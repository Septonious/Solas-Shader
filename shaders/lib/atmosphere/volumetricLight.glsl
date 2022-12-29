void computeVolumetricLight(inout vec3 vl, in vec3 translucent, in float dither) {
	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	//Positions
	vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
	vec3 viewPos = ToView(vec3(texCoord, z0));
	vec3 nViewPos = normalize(viewPos.xyz);

	float VoU = 1.0 - max(dot(nViewPos, upVec), 0.0);
	float VoL = exp(dot(nViewPos, lightVec) * 2.0) * 0.5;
	float nVoL = mix(1.0 + VoL, VoL * (1.0 - eBS * 0.5), timeBrightness);
	float visibility = mix(pow2(VoU), 1.0, timeBrightness) * int(z0 > 0.56);
		  visibility *= 4.0 - sunVisibility * 3.0;
		  visibility = mix(visibility, 1.0 + timeBrightness, float(isEyeInWater == 1));
		  visibility *= 0.0025;

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		vec3 shadowCol = vec3(0.0);

		float lViewPos = length(viewPos);
		float linearDepth0 = getLinearDepth(z0);
		float linearDepth1 = getLinearDepth(z1);

		float distanceFactor = mix(7.0 * (1.0 - timeBrightness * 0.5) + eBS * 3.0, 4.0, sign(isEyeInWater));

		//Ray marching and main calculations
		for (int i = 0; i < VL_SAMPLES; i++) {
			float currentDepth = (i + dither) * distanceFactor;

			if (linearDepth1 < currentDepth || (linearDepth0 < currentDepth && translucent.rgb == vec3(0.0))) {
				break;
			}

			vec3 worldPos = ToWorld(ToView(vec3(texCoord, getLogarithmicDepth(currentDepth))));

			if (length(worldPos) > 128.0) break;

			vec3 shadowPos = ToShadow(worldPos);

			float shadow0 = shadow2D(shadowtex0, shadowPos).z;

			//Colored Shadows
			#ifdef SHADOW_COLOR
			if (shadow0 < 1.0) {
				float shadow1 = shadow2D(shadowtex1, shadowPos.xyz).z;
				if (shadow1 > 0.0) {
					shadowCol = texture2D(shadowcolor0, shadowPos.xy).rgb * shadow1;
				}
			}
			#endif
			vec3 shadow = clamp(shadowCol * 8.0 * (1.0 - shadow0) + shadow0, 0.0, 1.0);

			#ifdef VL_CLOUDY_NOISE
			float noise = 1.0;

			if (rainStrength != 0.0 && isEyeInWater == 0) {
				vec3 npos = (worldPos + cameraPosition) * 0.75 + vec3(frameTimeCounter, 0.0, 0.0);
				float n3da = texture2D(noisetex, npos.xz * 0.0001 + floor(npos.y * 0.1) * 0.05).r;
				float n3db = texture2D(noisetex, npos.xz * 0.0001 + floor(npos.y * 0.1 + 1.0) * 0.05).r;
				noise = mix(n3da, n3db, fract(npos.y * 0.1));
				noise = sin(noise * 16.0 + frameTimeCounter * 0.5) * (0.4 + rainStrength * 0.2) + (0.6 - rainStrength * 0.2);
			}

			shadow *= mix(1.0, noise, rainStrength);
			#endif

			//Translucency Blending
			if (linearDepth0 < currentDepth) {
				shadow *= translucent.rgb;
			}

			vl += shadow;
		}

		vl *= visibility;
		vl *= mix(mix(lightCol, skyColor * lightCol, timeBrightness), waterColor, sign(isEyeInWater) * (1.0 - rainStrength * 0.5));
	}
}