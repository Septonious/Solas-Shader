float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

void computeVolumetricLight(inout vec3 vl, in vec3 translucent, in float dither) {
	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	//Positions
	vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
	vec3 viewPos = ToView(vec3(texCoord.xy, z0));
	vec3 nViewPos = normalize(viewPos);

	//Total Visibility
	float VoU = clamp(dot(nViewPos, upVec), 0.0, 1.0);
		  VoU = 1.0 - pow(VoU, 1.5);
		  VoU = mix(VoU, 1.0, timeBrightness * (1.0 - eBS * eBS));
	float VoL = clamp(dot(nViewPos, lightVec), 0.0, 1.0);

	float visibility = pow(VoU, (1.0 - float(isEyeInWater == 1) * 0.5) * (6.0 - timeBrightness * 4.0)) * int(z0 > 0.56);
	      visibility *= mix(exp(VoL) * 0.5, pow(VoL, (1.0 - float(isEyeInWater == 1) * 0.5) * 4.0 - VoL * 3.0), timeBrightness);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		vec3 shadowCol = vec3(0.0);
		vec3 vlColor = mix(pow(lightCol, vec3(0.75)), lightCol * normalize(skyColor + 0.000001), timeBrightness);

		//Linear Depths
		float linearDepth0 = getLinearDepth(z0);
		float linearDepth1 = getLinearDepth(z1);

		//Variables
		float lViewPos = length(viewPos);

		int sampleCount = int(mix(8, VL_SAMPLES, min(visibility, 1.0)));

		float maxDist = max(far, 96.0) * (0.5 - float(isEyeInWater == 1) * 0.25);
		float minDist = maxDist / sampleCount;
		float fovFactor = gbufferProjection[1][1] / 1.37;
		float x = abs(texCoord.x - 0.5);
			  x = 1.0 - x * x;
			  x = pow(x, max(3.0 - fovFactor, 0.0));
			  minDist *= x;
			  maxDist *= x;

		float maxCurrentDist = min(linearDepth1, maxDist);

		//Ray Marching
		for (int i = 0; i < sampleCount; i++) {
			float currentDist = (i + dither) * minDist;

			if (currentDist > maxCurrentDist) break;

			if (linearDepth1 < currentDist || (linearDepth0 < currentDist && translucent.rgb == vec3(0.0))) {
				break;
			}

            vec3 worldPos = ToWorld(ToView(vec3(texCoord, getLogarithmicDepth(currentDist))));
            vec3 shadowPos = ToShadow(worldPos);

			if (length(shadowPos.xy * 2.0 - 1.0) < 1.0) {
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

				#ifdef VL_CLOUDY_NOISE
				float noise = 1.0;

				if (isEyeInWater == 0) {
					vec3 npos = worldPos + cameraPosition + vec3(frameTimeCounter, 0.0, 0.0);
					float n3da = texture2D(noisetex, npos.xz * 0.0005 + floor(npos.y * 0.1) * 0.1).r;
					float n3db = texture2D(noisetex, npos.xz * 0.0005 + floor(npos.y * 0.1 + 1.0) * 0.1).r;
					noise = sin(mix(n3da, n3db, fract(npos.y * 0.1)) * 16.0) * 0.4 + 0.6;
				}

				shadow0 *= noise;
				#endif

				vec3 shadow = clamp(shadow1 * pow2(shadowCol) * 2.0 + shadow0 * vlColor * float(isEyeInWater == 0), 0.0, 8.0);

				//Translucency Blending
				if (linearDepth0 < currentDist) {
					shadow *= translucent.rgb;
				}

				float currentSampleIntensity = pow4(min(currentDist * 0.33, 1.0)) * (currentDist / maxDist) / sampleCount;

				vl += shadow * currentSampleIntensity;
			}
		}

		vl *= visibility;
		if (isEyeInWater == 1.0) vl *= mix(waterColorSqrt, waterColorSqrt * weatherCol, wetness) * (4.0 + sunVisibility * 16.0);
	}
}