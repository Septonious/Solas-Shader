float texture2DShadow(sampler2D shadowtex, vec3 shadowPos, float lod) {
    float shadow = texture2DLod(shadowtex, shadowPos.xy, lod).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

void getCloudSample(vec3 sunVec, vec2 rayPos, vec2 wind, float attenuation, inout float noise, inout float lightingNoise) {
	rayPos *= 0.00025;

	float noiseBase = texture2D(noisetex, rayPos + 0.5 + wind * 0.5).g;
		  noiseBase = pow2(1.0 - noiseBase) * 0.5 + 0.25;

	//float noiseBaseL = texture2D(noisetex, (rayPos + normalize(ToWorld(sunVec * 10000000.0)).xy * 0.3) + 0.5 + wind * 0.5).g;
	//	  noiseBaseL = pow2(1.0 - noiseBaseL) * 0.5 + 0.25;

	float detailZ = floor(attenuation * VF_END_THICKNESS) * 0.05;
	float noiseDetailA = texture2D(noisetex, rayPos * 1.5 - wind + detailZ).b;
	float noiseDetailB = texture2D(noisetex, rayPos * 1.5 - wind + detailZ + 0.05).b;
	float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * VF_END_THICKNESS));

	float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.14 : 8.0);
		  noiseCoverage *= noiseCoverage * 8.0;
	
	noise = mix(noiseBase, noiseDetail, 0.05 * int(noiseBase > 0.0)) * 22.0 - noiseCoverage;
	noise = max(noise - VF_END_AMOUNT, 0.0) * 0.75;
	noise /= sqrt(noise * noise + 0.25);

	//lightingNoise = noiseBaseL * 22.0 - noiseCoverage;
	//lightingNoise = mix(lightingNoise, 22.0, wetness * 0.2);
	//lightingNoise = max(lightingNoise - VF_END_AMOUNT, 0.0) * (cloudDensity * 0.2);
	//lightingNoise /= sqrt(lightingNoise * lightingNoise + 0.25);
}

void computeVolumetricClouds(inout vec4 vc, float dither, inout float currentDepth) {
	//Total visibility
	float z0 = texture2D(depthtex0, texCoord).r;
	float visibility = int(z0 > 0.56);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Positions
		vec3 viewPos = ToView(vec3(texCoord, z0));
		vec3 nViewPos = normalize(viewPos);
		vec3 nWorldPos = normalize(ToWorld(viewPos));

		//Setting the ray marcher
		float cloudTop = VF_END_HEIGHT + VF_END_THICKNESS * 10.0;
		float lowerPlane = (VF_END_HEIGHT - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (cloudTop - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = max(lowerPlane, upperPlane);

		float planeDifference = maxDist - minDist;
		float rayLength = VF_END_THICKNESS * 5.0;
			  rayLength /= nWorldPos.y * nWorldPos.y * 3.0 + 1.0;
		vec3 startPos = cameraPosition + minDist * nWorldPos;
		vec3 sampleStep = nWorldPos * rayLength;
		int sampleCount = int(min(planeDifference / rayLength, 32) + dither);

		if (maxDist >= 0.0 && sampleCount > 0) {
			float cloud = 0.0;
			float cloudAlpha = 0.0;
			float cloudLighting = 0.0;

			//Scattering variables
			float VoU = dot(nViewPos, upVec);
			float VoL = dot(nViewPos, -sunVec);
			float halfVoLSqrt = VoL * shadowFade * 0.5 + 0.5;
			float halfVoL = halfVoLSqrt * halfVoLSqrt;
			float scattering = pow6(halfVoLSqrt);
			float noiseLightFactor = (2.0 - VoL * shadowFade) * 5.0;

			vec3 rayPos = startPos + sampleStep * dither;
			
			float maxDepth = currentDepth;
			float minimalNoise = 0.25 + dither * 0.25;
			float sampleTotalLength = minDist + rayLength * dither;

			vec2 wind = vec2(frameTimeCounter * VC_SPEED * 0.0005, sin(frameTimeCounter * VC_SPEED * 0.001) * 0.005) * VF_END_HEIGHT * 0.005;

			//Ray marcher
			for (int i = 0; i < sampleCount; i++, rayPos += sampleStep, sampleTotalLength += rayLength) {
				if (cloudAlpha > 0.99 || (sampleTotalLength > length(viewPos) && z0 < 1.0)) break;

                vec3 worldPos = rayPos - cameraPosition;

				float shadow0 = clamp(texture2DShadow(shadowtex0, ToShadow(worldPos), 2), 0.0, 1.0);

				float noise = 0.0;
				float lightingNoise = 0.0;
				float rayDistance = length(worldPos.xz) * 0.1;
				float attenuation = smoothstep(VF_END_HEIGHT, cloudTop, rayPos.y);

				getCloudSample(-sunVec, rayPos.xz, wind, attenuation, noise, lightingNoise);

				float sampleLighting = pow(attenuation, 0.9 + halfVoL * 1.1) * 1.25 + 0.25;
					  sampleLighting *= 1.0 - pow(noise, noiseLightFactor);

				//cloudLighting = mix(cloudLighting, sampleLighting * mix(1.0, clamp((noise - sqrt(lightingNoise)), 0.0, 1.0), 0.7), noise * (1.0 - cloud * cloud));
				cloudLighting = mix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));
				noise *= shadow0;
				cloud = mix(cloud, 1.0, noise);
				noise *= pow24(smoothstep(386.0, 8.0, rayDistance)); //Fog
				cloudAlpha = mix(cloudAlpha, 1.0, noise);

				//gbuffers_water cloud discard check
				if (noise > minimalNoise && currentDepth == maxDepth) {
					currentDepth = sampleTotalLength;
				}
			}

			//Final color calculations
			vec3 cloudColor = mix(endAmbientCol * 0.2, endLightCol * 0.4, cloudLighting) * (1.0 + scattering * 3.0);

			vc = vec4(cloudColor, cloudAlpha * VF_END_OPACITY) * visibility;
		}
	}
}