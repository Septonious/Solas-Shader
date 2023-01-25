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
		  VoU = 1.0 - VoU;
		  VoU = mix(VoU, 1.0, timeBrightness);
	float VoL = clamp(dot(nViewPos, lightVec), 0.0, 1.0);
		  VoL = exp(VoL * 2.0) * 0.5;
		  VoL = mix(0.5 + VoL, VoL, timeBrightness);

	float visibility = 0.0025 * (3.0 - sunVisibility * 2.0);
		  visibility *= mix(pow3(VoU) * VoL, VoU * 2.0, rainStrength) * int(z0 > 0.56);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		vec3 shadowCol = vec3(0.0);

		//Linear Depths
		float linearDepth0 = getLinearDepth(z0);
		float linearDepth1 = getLinearDepth(z1);

		//Variables
		float distanceFactor = mix(8.0, 4.0, float(isEyeInWater == 1));
		float lViewPos = length(viewPos);

		//Ray Marching
		for (int i = 0; i < VL_SAMPLES; i++) {
			float currentDepth = (i + dither) * distanceFactor;

			if (linearDepth1 < currentDepth || (linearDepth0 < currentDepth && translucent.rgb == vec3(0.0))) {
				break;
			}

			vec3 worldPos = ToWorld(ToView(vec3(texCoord, getLogarithmicDepth(currentDepth))));

			if (length(worldPos) > 196.0) break;

			//Shadows
			vec3 shadowPos = ToShadow(worldPos);

			float shadow0 = shadow2D(shadowtex0, shadowPos).z;

			#ifdef SHADOW_COLOR
			if (shadow0 < 1.0) {
				float shadow1 = shadow2D(shadowtex1, shadowPos.xyz).z;
				if (shadow1 > 0.0) {
					shadowCol = texture2D(shadowcolor0, shadowPos.xy).rgb;
					shadowCol *= shadow1 * 4.0;
				}
			}
			#endif
			vec3 shadow = clamp(shadowCol * (1.0 - shadow0) + shadow0, 0.0, 1.0);

			#ifdef VL_CLOUDY_NOISE
			float noise = 1.0;

			if (rainStrength != 0.0 && isEyeInWater == 0) {
				vec3 npos = (worldPos + cameraPosition) * 0.75 + vec3(frameTimeCounter, 0.0, 0.0);
				float n3da = texture2D(shadowcolor1, npos.xz * 0.0005 + floor(npos.y * 0.1) * 0.05).r;
				float n3db = texture2D(shadowcolor1, npos.xz * 0.0005 + floor(npos.y * 0.1 + 1.0) * 0.05).r;
				noise = mix(noise, sin(mix(n3da, n3db, fract(npos.y * 0.1)) * 16.0 + 0.3 + frameTimeCounter * 0.2) * 0.5 + 0.5, rainStrength);
			}

			shadow *= noise;
			#endif

			//Translucency Blending
			if (linearDepth0 < currentDepth) {
				shadow *= translucent.rgb;
			}

			vl += shadow;
		}

		vl *= mix(mix(lightCol, lightCol * skyColor, timeBrightness * 0.5), waterColor, sign(isEyeInWater));
		vl *= visibility;
	}
}