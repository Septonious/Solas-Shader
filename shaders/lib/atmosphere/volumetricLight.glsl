float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

void computeVL(inout vec3 vl, in vec3 translucent, in float dither) {
	vec3 finalVL = vec3(0.0);

	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	//Positions
	vec3 viewPos = ToView(vec3(texCoord.xy, z0));
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
	vec3 worldSunVec = mat3(gbufferModelViewInverse) * lightVec;
	vec3 nViewPos = normalize(viewPos);

    //Total Visibility & Variables
    float indoorFactor = (1.0 - eBS * eBS) * float(isEyeInWater == 0 && cameraPosition.y < 1000.0);
	#if MC_VERSION >= 12104
		  indoorFactor = mix(indoorFactor, 1.0, isPaleGarden * 0.5);
	#endif

	float VoL = dot(nViewPos, lightVec);
	float VoLC = clamp(VoL, 0.0, 1.0);
		  VoLC = mix(VoLC, 0.5, 0.25 * float(isEyeInWater == 1));
	float VoLP = 1.0 + VoL;

	#ifdef OVERWORLD
	float waterFactor = 1.0 - float(isEyeInWater == 1) * 0.5;
	float denseForestFactor = min(isSwamp + isJungle, 1.0);
	float meVisRatio = (1.0 - VL_STRENGTH_RATIO) + pow(VoLC, 1.3) * VL_STRENGTH_RATIO;
	float visibility = float(0.56 < z0) * shadowFade * VoLP;
		  visibility *= mix(meVisRatio, 4.0 - sunVisibility * 3.25, min(timeBrightness + (1.0 - sunVisibility), 1.0));
		  visibility = mix(visibility * (1.0 + denseForestFactor * 0.5), 0.5, indoorFactor) * waterFactor;
		  visibility *= caveFactor;
	#else
	float dragonBattle = gl_Fog.start / far;
	float endBlackHolePos = pow2(clamp(dot(nViewPos, sunVec), 0.0, 1.0));
	float visibilityNormal = endBlackHolePos * 0.25;
	float visibilityDragon = 0.5 + endBlackHolePos;
	float visibility = float(0.56 < z0) * mix(visibilityDragon, visibilityNormal, clamp(dragonBattle, 0.0, 1.0));
	#endif

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Linear Depths
		float linearDepth0 = getLinearDepth2(z0);
		float linearDepth1 = getLinearDepth2(z1);

		//Variables
		#ifdef OVERWORLD
		int sampleCount = int(VL_SAMPLES + 2 * mefade);
		#ifdef DISTANT_HORIZONS
			sampleCount += 4;
		#endif
		#else
		int sampleCount = VL_SAMPLES;
		#endif

		float maxDist = shadowDistance;
		#ifdef VC_SHADOWS
			 maxDist += 200.0;
		#endif
		#ifdef DISTANT_HORIZONS
			  maxDist += min(dhRenderDistance, 400.0);
		#endif
		float minDist = (maxDist / sampleCount) * (0.5 + min(length(viewPos * 0.5), 1.5));

		#if MC_VERSION >= 12100
			  minDist *= 1.0 - isPaleGarden * 0.35;
		#endif

		float maxCurrentDist = min(linearDepth1, maxDist);

		vec3 shadowCol = vec3(0.0);
		vec3 newSkyColor = pow(normalize(skyColor + 0.0001), vec3(0.75));

		//Cloud Shadows Paramteres
		#ifdef VC_SHADOWS
		float speed = VC_SPEED;
		float amount = VC_AMOUNT;
		float frequency = VC_FREQUENCY;
		float density = VC_DENSITY;
		float height = VC_HEIGHT;
		float cloudTop = VC_HEIGHT + VC_THICKNESS + 75.0 - timeBrightness * 30.0;

		getDynamicWeather(speed, amount, frequency, density, height);

		vec2 wind = vec2(frameTimeCounter * speed * 0.005, sin(frameTimeCounter * speed * 0.1) * 0.01) * speed * 0.1;
		#endif

		//Ray Marching
		for (int i = 0; i < sampleCount; i++) {
			float currentDist = (i + dither) * minDist;
            	  currentDist = mix(currentDist, exp2(i + dither) - 0.95, min(indoorFactor + timeBrightness, 1.0));

			if (currentDist > maxCurrentDist || linearDepth1 < currentDist || (linearDepth0 < currentDist && translucent.rgb == vec3(0.0))) {
				break;
			}

            vec3 worldPos = ToWorld(ToView(vec3(texCoord, getLogarithmicDepth(currentDist))));
            vec3 shadowPos = ToShadow(worldPos);

			if (length(shadowPos.xy * 2.0 - 1.0) < 1.0) {
                float currentSampleIntensity = (currentDist / maxDist) / sampleCount;
                      currentSampleIntensity = pow(currentSampleIntensity, 0.8 - min(indoorFactor + timeBrightness, 1.0) * 0.3);

				float shadow0 = texture2DShadow(shadowtex0, shadowPos);
				float shadow1 = 0.0;

				#ifdef SHADOW_COLOR
				if (shadow0 < 1.0) {
					shadow1 = texture2DShadow(shadowtex1, shadowPos);
					if (shadow1 > 0.0) {
						shadowCol = texture2D(shadowcolor0, shadowPos.xy).rgb;
					}
				}
				#endif

				#ifdef OVERWORLD
				vec3 vlColor = mix(pow(lightCol, vec3(0.85)), lightCol * newSkyColor, timeBrightness);
				#else
				vec3 vlColor = endLightColSqrt;
				#endif

				vec3 shadow = clamp(shadow1 * pow2(shadowCol) + shadow0 * vlColor * float(isEyeInWater == 0), 0.0, 8.0);

				//Crepuscular rays
				#ifdef VC_SHADOWS
				if (worldPos.y +cameraPosition.y < cloudTop) {
					vec3 cloudShadowPos = worldPos + cameraPosition + (worldSunVec / max(abs(worldSunVec.y), 0.0)) * max(cloudTop - worldPos.y - cameraPosition.y, 0.0);

					float noise = 0.0;
					getCloudShadow(cloudShadowPos.xz, wind, amount, frequency, density, noise);
					shadow *= noise;
				}
				shadow *= 1.0 - min((worldPos.y + cameraPosition.y - VC_THICKNESS) * (1.0 / cloudTop), 1.0);
				#endif

				//Translucency Blending
				if (linearDepth0 < currentDist) {
					shadow *= translucent.rgb;
				}

				finalVL += shadow * currentSampleIntensity;
			}
		}

        finalVL *= visibility;
		if (isEyeInWater == 1.0) finalVL *= mix(waterColorSqrt, waterColorSqrt * weatherCol, wetness) * (4.0 + sunVisibility * 4.0);
	}
    vl += finalVL * VL_STRENGTH;
}