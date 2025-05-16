float getCloudNoise(vec2 rayPos) {
	const float roundness = 0.2;
	rayPos = rayPos * 0.05 + 0.5;
	vec2 a, b = modf(1.0 + abs(rayPos), a);
	b = smoothstep(0.5 - roundness, roundness + 0.5, b);
	vec2 noiseCoord = sign(rayPos) * (a + b - 0.5) / 256.0;
	
	return float(0 < texture2D(shadowcolor1, noiseCoord).r);
}

float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

void computeVolumetricClouds(inout vec4 vc, in vec3 atmosphereColor, in float z1, in float dither, inout float cloudDepth) {
	//Total visibility of clouds
	float visibility = caveFactor * int(0.56 < z1);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (0 < visibility) {
		//Positions & Variables
		vec3 viewPos = ToView(vec3(texCoord, z1));
		vec3 nWorldPos = normalize(ToWorld(viewPos));
		float distanceFactor = VC_DISTANCE;
		#ifdef DISTANT_HORIZONS
			  distanceFactor *= 2.0;
		#endif
		
		//Set the two planes here between which the ray marching will be done
		const float stretching = 8.0;
		float lowerPlane = (VC_HEIGHT + stretching - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (VC_HEIGHT - stretching - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = min(max(lowerPlane, upperPlane), distanceFactor);
		float rayLength = maxDist - minDist;

		float sampleTotalLength = minDist + rayLength * dither;

		int sampleCount = clamp(int(rayLength), 0, 24);

		if (0 < sampleCount) {
			//Other variables
			vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
			vec3 worldLightVec = normalize(ToWorld(lightVec * 1000000.0));
			float lViewPos = length(viewPos);
			float lViewPosFar = lViewPos < far ? lViewPos - 1.0 : 99999999.0;

			#ifdef DISTANT_HORIZONS
			float dhZ = texture2D(dhDepthTex0, texCoord).r;
			vec4 dhScreenPos = vec4(texCoord, dhZ, 1.0);
			vec4 dhViewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
				 dhViewPos /= dhViewPos.w;

			float lViewPosDH = length(dhViewPos);
			float lViewPosDHFar = lViewPosDH < dhFarPlane ? lViewPosDH - 1.0 : 99999999.0;
			#endif

			//Blend colors with the sky
            float morningEveningFactor = mix(1.0, 0.66, sqrt(sunVisibility) * (1.0 - timeBrightnessSqrt));

			vec3 cloudAmbientColor = mix(ambientCol, atmosphereColor * atmosphereColor, 0.4 * sunVisibility);
                 cloudAmbientColor *= 0.4 + sunVisibility * sunVisibility * (0.2 - wetness * 0.2);
			vec3 cloudLightColor = mix(lightCol, mix(lightCol, atmosphereColor * 2.25, 0.25 * (sunVisibility + timeBrightness)) * atmosphereColor * 2.25, sunVisibility);
                 cloudLightColor *= morningEveningFactor;

			//Precompute the ray position
			vec3 rayPos = cameraPosition + nWorldPos * minDist;
			vec3 rayDir = nWorldPos * (rayLength / sampleCount);
			rayPos += rayDir * dither;
			rayPos.y -= rayDir.y;

			float cloudAlpha = 0.0;
			float maxDepth = cloudDepth;
			float minimalNoise = 0.25 + dither * 0.25;
			float cloudLighting = 0.0;

			//Ray marching
			for (int i = 0; i < sampleCount; i++, sampleTotalLength += rayLength) {
				rayPos += rayDir;
				vec3 worldPos = rayPos - cameraPosition;

				float lWorldPos = length(worldPos);
				float lWorldPosXZ = length(worldPos.xz);

				if (0.99 < cloudAlpha || lViewPosFar < lWorldPos || distanceFactor < lWorldPosXZ) break;

				#ifdef DISTANT_HORIZONS
				if (lViewPosDHFar < lWorldPos) break;
				#endif

				float shadowSample = 1.0;
				float shadowLength = clamp(shadowDistance * 0.9166667 - length(worldPos.xz), 0.0, 1.0);

				#ifdef VC_LIGHTRAYS
				shadowSample = texture2DShadow(shadowtex1, ToShadow(worldPos));
				#endif

				//Indoor leak prevention
				if (eyeBrightnessSmooth.y < 220.0 && 0 < shadowLength) {
					#ifndef VC_LIGHTRAYS
					shadowSample = texture2DShadow(shadowtex1, ToShadow(worldPos));
					#endif
					if (shadowSample == 0.0) break;
				}

				//Shaping
				float noise = getCloudNoise(rayPos.xz);
				float noiseL = getCloudNoise(rayPos.xz + worldLightVec.xz * 2.0);

				cloudAlpha = mix(cloudAlpha, 1.0, noise);

				//gbuffers_water cloud discard check
				if (minimalNoise < noise && cloudDepth == maxDepth) {
					cloudDepth = pow(sampleTotalLength, 0.5);
				}

				//Lighting calculations
				cloudLighting = clamp(smoothstep(VC_HEIGHT + stretching * noise, VC_HEIGHT - stretching * noise, rayPos.y), 0.0, 1.0);
				cloudLighting = mix(cloudLighting, 1.0, (noiseL - noise * 0.5) * shadowFade);
			}
			vec3 cloudColor = mix(cloudLightColor, cloudAmbientColor, cloudLighting);

			vc = vec4(cloudColor, cloudAlpha * min(VC_OPACITY + 0.1, 1.0)) * visibility;
		}
	}
	vc *= visibility;
}