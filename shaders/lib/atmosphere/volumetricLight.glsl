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
	vec3 nViewPos = normalize(viewPos);

    //Total Visibility
    float indoorFactor = (1.0 - eBS * eBS) * float(isEyeInWater == 0 && cameraPosition.y < 1000.0);
	float VoU = clamp(dot(nViewPos, upVec), 0.0, 1.0);
		  VoU = 1.0 - pow(VoU, 1.5);
		  VoU = mix(VoU, 1.0, min(indoorFactor + timeBrightness, 1.0) * 0.75);
	float VoL = pow(clamp(dot(nViewPos, lightVec), 0.0, 1.0), 1.5);

	float vlVisibility = int(z0 > 0.56) * shadowFade;
	#ifdef OVERWORLD
	float waterFactor = 1.0 - float(isEyeInWater == 1) * 0.5;
		  vlVisibility *= pow(VoU, 3.0 * waterFactor);
		  vlVisibility *= mix(0.25 + VoL * 0.25, VoL * 0.4, timeBrightness);
		  vlVisibility = mix(vlVisibility * (2.0 - sunVisibility), 0.5, indoorFactor) * waterFactor;
	#else
		  vlVisibility = exp(pow4(VoL)) * 0.075;
	#endif

	#if MC_VERSION >= 11900
	vlVisibility *= 1.0 - darknessFactor;
	#endif

	vlVisibility *= 1.0 - blindFactor;

	if (vlVisibility > 0.0) {
		//Linear Depths
		float linearDepth0 = getLinearDepth(z0);
		float linearDepth1 = getLinearDepth(z1);

		//Variables
        int sampleCount = VL_SAMPLES;

		float maxDist = 96.0;
		float minDist = (maxDist / sampleCount * (1.0 - float(isEyeInWater == 1) * 0.5));
		float maxCurrentDist = min(linearDepth1, maxDist);

		vec3 shadowCol = vec3(0.0);
		vec3 newSkyColor = pow(normalize(skyColor + 0.0001), vec3(0.75));

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
                      currentSampleIntensity = pow(currentSampleIntensity, 1.0 - min(indoorFactor + timeBrightness, 1.0) * 0.5);

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

				#ifdef VL_CLOUDY_FOG
				float noise = 1.0;

				if (isEyeInWater == 0) {
					vec3 npos = worldPos + cameraPosition + vec3(frameTimeCounter, 0.0, 0.0);

                    float altitudeFactor = clamp(1.0 - npos.y * 0.005, 0.0, 1.0);
					float n3da = texture2D(noisetex, npos.xz * 0.00025 + floor(npos.y * 0.05) * 0.05).r;
					float n3db = texture2D(noisetex, npos.xz * 0.00025 + floor(npos.y * 0.05 + 1.0) * 0.05).r;

					vlColor = mix(vlColor, newSkyColor, 0.25 * altitudeFactor * (sunVisibility - timeBrightness));

					noise = mix(n3da, n3db, fract(npos.y * 0.05));
                    noise = max(noise - 0.25, 0.0);
                    noise = min(noise * 4.0, 1.0);
                    noise *= noise * noise;
                    noise = mix(1.0, noise * (3.0 - timeBrightness * 2.0), altitudeFactor * altitudeFactor);
				}

				shadow0 *= noise;
				#endif

				vec3 shadow = clamp(shadow1 * pow2(shadowCol) + shadow0 * vlColor * float(isEyeInWater == 0), 0.0, 8.0);

				//Translucency Blending
				if (linearDepth0 < currentDist) {
					shadow *= translucent.rgb;
				}

				finalVL += shadow * currentSampleIntensity;
			}
		}

        finalVL *= vlVisibility * VL_STRENGTH;
		if (isEyeInWater == 1.0) finalVL *= mix(waterColorSqrt, waterColorSqrt * weatherCol, wetness) * (4.0 + sunVisibility * 8.0);
	}
    vl += pow(finalVL, vec3(1.0 - pow(length(finalVL), 1.5) * 0.25));
}