#ifdef VC_DYNAMIC_WEATHER
float day = float(worldDay % 14);
float mixFactor = 0.6 + sunVisibility * 0.4;

float cloudHeight = mix(mix(VC_HEIGHT, min(day * 15.0 + 100.0, 250.0), mixFactor), 100.0, wetness);
float cloudDensity = mix(VC_DENSITY, clamp(day, 4.0, 10.0), mixFactor);
float cloudAmount = mix(VC_AMOUNT, clamp(day * 2.0, 10.0, 12.0), mixFactor);
float cloudThickness = mix(mix(VC_THICKNESS, clamp(day, 4.0, 8.0), mixFactor), 18.0, wetness);
#else
float cloudHeight = mix(VC_HEIGHT, 100.0, wetness);
float cloudDensity = VC_DENSITY;
float cloudAmount = VC_AMOUNT;
float cloudThickness = mix(VC_THICKNESS, 18.0, wetness);
#endif

uniform vec4 lightningBoltPosition;

float lightningFlashEffect(vec3 worldPos, vec3 lightningBoltPosition, float lightDistance){ //Thanks to Xonk!
    vec3 lightningPos = worldPos - vec3(lightningBoltPosition.x, max(worldPos.y, lightningBoltPosition.y), lightningBoltPosition.z);

    float lightningLight = max(1.0 - length(lightningPos) / lightDistance, 0.0);
          lightningLight = exp(-24.0 * (1.0 - lightningLight));

    return lightningLight;
}

void getCloudSample(vec3 lightVec, vec2 rayPos, vec2 wind, float attenuation, inout float noise, inout float lightingNoise) {
	rayPos *= 0.0002;

	float noiseBase = texture2D(noisetex, rayPos + 0.5 + wind * 0.5).g;
		  noiseBase = pow2(1.0 - noiseBase) * 0.5 + 0.25;

	//float noiseBaseL = texture2D(noisetex, (rayPos + normalize(ToWorld(lightVec * 10000000.0)).xy * 0.3) + 0.5 + wind * 0.5).g;
	//	  noiseBaseL = pow2(1.0 - noiseBaseL) * 0.5 + 0.25;

	float detailZ = floor(attenuation * cloudThickness) * 0.05;
	float noiseDetailA = texture2D(noisetex, rayPos * 1.5 - wind + detailZ).b;
	float noiseDetailB = texture2D(noisetex, rayPos * 1.5 - wind + detailZ + 0.05).b;
	float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * cloudThickness));

	float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.14 : 8.0);
		  noiseCoverage *= noiseCoverage * 6.0;
	
	noise = mix(noiseBase, noiseDetail, VC_DETAIL * 0.05 * int(noiseBase > 0.0)) * 22.0 - noiseCoverage;
	noise = mix(noise, 20.0, wetness * 0.2);
	noise = max(noise - cloudAmount, 0.0) * (cloudDensity * 0.2);
	noise /= sqrt(noise * noise + 0.25);

	//lightingNoise = noiseBaseL * 22.0 - noiseCoverage;
	//lightingNoise = mix(lightingNoise, 22.0, wetness * 0.2);
	//lightingNoise = max(lightingNoise - cloudAmount, 0.0) * (cloudDensity * 0.2);
	//lightingNoise /= sqrt(lightingNoise * lightingNoise + 0.25);
}

void computeVolumetricClouds(inout vec4 vc, in vec3 atmosphereColor, float z1, float dither, inout float currentDepth) {
	//Total visibility
	float visibility = caveFactor * int(z1 > 0.56);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Positions
		vec3 viewPos = ToView(vec3(texCoord, z1));
		vec3 nViewPos = normalize(viewPos);
		vec3 nWorldPos = normalize(ToWorld(viewPos));
		vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

		//Setting the ray marcher
		float cloudTop = cloudHeight + cloudThickness * 10.0;
		float lowerPlane = (cloudHeight - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (cloudTop - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = max(lowerPlane, upperPlane);

		float planeDifference = maxDist - minDist;
		float rayLength = cloudThickness * 5.0;
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
			float VoL = dot(nViewPos, lightVec);
			float halfVoLSqrt = VoL * shadowFade * 0.5 + 0.5;
			float halfVoL = halfVoLSqrt * halfVoLSqrt;
			float scattering = pow6(halfVoLSqrt);
			float noiseLightFactor = (2.0 - VoL * shadowFade) * cloudDensity;

			vec3 rayPos = startPos + sampleStep * dither;
			
			float maxDepth = currentDepth;
			float minimalNoise = 0.25 + dither * 0.25;
			float sampleTotalLength = minDist + rayLength * dither;

			vec2 wind = vec2(frameTimeCounter * VC_SPEED * 0.0005, sin(frameTimeCounter * VC_SPEED * 0.001) * 0.005) * cloudHeight * 0.005;

			//Ray marcher
			for (int i = 0; i < sampleCount; i++, rayPos += sampleStep, sampleTotalLength += rayLength) {
				if (cloudAlpha > 0.99 || (sampleTotalLength > length(viewPos) && z1 < 1.0)) break;

                vec3 worldPos = rayPos - cameraPosition;

				//Indoor leak prevention
				if (eyeBrightnessSmooth.y < 200.0) {
					if (shadow2D(shadowtex1, ToShadow(worldPos)).z == 0.0) break;
				}

				float noise = 0.0;
				float lightingNoise = 0.0;
				float rayDistance = length(worldPos.xz) * 0.1;
				float attenuation = smoothstep(cloudHeight, cloudTop, rayPos.y);

				getCloudSample(lightVec, rayPos.xz, wind, attenuation, noise, lightingNoise);

				float sampleLighting = pow(attenuation, 0.9 + halfVoL * 1.1) * 1.25 + 0.25;
					  sampleLighting *= 1.0 - pow(noise, noiseLightFactor);

				//cloudLighting = mix(cloudLighting, sampleLighting * mix(1.0, clamp((noise - sqrt(lightingNoise)), 0.0, 1.0), 0.7), noise * (1.0 - cloud * cloud));
				cloudLighting = mix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));
				cloud = mix(cloud, 1.0, noise);
				noise *= pow24(smoothstep(VC_DISTANCE - 150.0 * wetness, 32.0, rayDistance)); //Fog
				cloudAlpha = mix(cloudAlpha, 1.0, noise);

                #ifdef IS_IRIS
                    float lightning = min(lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 256.0) * lightningBoltPosition.w * 4.0, 1.0);
					cloudLighting = mix(cloudLighting, pow(sampleLighting, 0.25) * 6.0, lightning);
                #endif

				//gbuffers_water cloud discard check
				if (noise > minimalNoise && currentDepth == maxDepth) {
					currentDepth = sampleTotalLength;
				}
			}

			//Final color calculations
			vec3 cloudAmbientColor = mix(ambientCol, atmosphereColor, 0.35 * sunVisibility) * (0.35 + sunVisibility * sunVisibility * 0.3);
			vec3 cloudLightColor = mix(lightCol, atmosphereColor, 0.15 * sunVisibility) * (1.0 + scattering * 2.0);
			vec3 cloudColor = mix(cloudAmbientColor, cloudLightColor, cloudLighting);

			float opacity = clamp(mix(0.99, VC_OPACITY, float(z1 == 1.0 || cameraPosition.y < cloudHeight)), 0.0, 1.0 - wetness * 0.6);

			vc = vec4(cloudColor, cloudAlpha * opacity) * visibility;
		}
	}
}