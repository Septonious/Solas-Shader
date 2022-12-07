void computeVolumetricLight(inout vec3 vl, in vec3 translucent, in float dither) {
	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	//Positions
	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec3 nViewPos = normalize(viewPos.xyz);

	float VoU = 1.0 - max(dot(nViewPos, upVec), 0.0);

	vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
	float VoL = dot(nViewPos, lightVec);
	float sunFactor = exp(VoL * 2.0) * 0.5;
	float nVoL = mix((0.75 + sunFactor) * 0.75, sunFactor * (1.5 - eBS), timeBrightness);
	float visibility = float(z0 > 0.56) * max(VoU * nVoL, sign(isEyeInWater)) * 0.02 * VL_OPACITY;

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		vec3 shadowCol = vec3(0.0);

		float lViewPos = length(viewPos);
		float linearDepth0 = getLinearDepth(z0);
		float linearDepth1 = getLinearDepth(z1);

		float distanceFactor = 7.0 + eBS * 2.0 - sign(isEyeInWater) * 4.0;

		//Ray marching and main calculations
		for (int i = 0; i < VL_SAMPLES; i++) {
			float currentDepth = pow(i + dither + eBS * 0.75, 1.5) * distanceFactor;

			if (linearDepth1 < currentDepth || (linearDepth0 < currentDepth && translucent.rgb == vec3(0.0))) {
				break;
			}

			vec3 worldPos = calculateWorldPos(getLogarithmicDepth(currentDepth), texCoord);

			float lWorldPos = length(worldPos);

			if (lWorldPos > far) break;

			vec3 shadowPos = calculateShadowPos(worldPos);
			shadowPos.z += 0.0512 / shadowMapResolution;

			if (length(shadowPos.xy * 2.0 - 1.0) < 1.0) {
				float shadow0 = shadow2D(shadowtex0, shadowPos).z;

				//Colored Shadows
				#ifdef SHADOW_COLOR
				if (shadow0 < 1.0) {
					float shadow1 = shadow2D(shadowtex1, shadowPos.xyz).z;
					if (shadow1 > 0.0) {
						shadowCol = texture2D(shadowcolor0, shadowPos.xy).rgb;
						shadowCol *= shadowCol * shadow1;
					}
				}
				#endif
				vec3 shadow = clamp(shadowCol * 8.0 * (1.0 - shadow0) + shadow0, vec3(0.0), vec3(1.0));

				//Translucency Blending
				if (linearDepth0 < currentDepth) {
					shadow *= translucent.rgb;
				}

				vl += shadow;
			}
		}

		vl *= visibility;
		vl *= lightCol;
	}
}