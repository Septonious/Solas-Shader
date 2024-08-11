float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

#ifdef VC
float cloudHeight = mix(VC_HEIGHT, 100.0, wetness);
float cloudDensity = VC_DENSITY;
float cloudAmount = VC_AMOUNT * (1.1 - sunVisibility * 0.1) * (1.0 - wetness * 0.15);
float cloudThickness = mix(VC_THICKNESS, 16.0, wetness);

uniform vec4 lightningBoltPosition;

float lightningFlashEffect(vec3 worldPos, vec3 lightningBoltPosition, float lightDistance){ //Thanks to Xonk!
    vec3 lightningPos = worldPos - vec3(lightningBoltPosition.x, max(worldPos.y, lightningBoltPosition.y), lightningBoltPosition.z);

    float lightningLight = max(1.0 - length(lightningPos) / lightDistance, 0.0);
          lightningLight = exp(-24.0 * (1.0 - lightningLight));

    return lightningLight;
}

void getCloudSample(vec2 rayPos, vec2 wind, float attenuation, inout float noise) {
	rayPos *= 0.000125 * VC_FREQUENCY;

	float noiseBase = texture2D(noisetex, rayPos + 0.5 + wind * 0.5).g;
		  noiseBase = pow2(1.0 - noiseBase) * 0.5 + 0.3;

	float detailZ = floor(attenuation * cloudThickness) * 0.05;
	float noiseDetailA = texture2D(noisetex, rayPos * 1.5 - wind + detailZ).b;
	float noiseDetailB = texture2D(noisetex, rayPos * 1.5 - wind + detailZ + 0.05).b;
	float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * cloudThickness));

	float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.14 : 8.0);
		  noiseCoverage *= noiseCoverage * 6.0;
	
	noise = mix(noiseBase, noiseDetail, VC_DETAIL * mix(0.05, 0.025, min(wetness + cameraPosition.y * 0.0025, 1.0)) * int(noiseBase > 0.0)) * 22.0 - noiseCoverage;
	noise = mix(noise, 20.0, wetness * 0.125);
	noise = max(noise - cloudAmount, 0.0) * (cloudDensity * 0.2);
	noise /= sqrt(noise * noise + 0.25);
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
		float rayLength = cloudThickness * 2.5;
			  rayLength /= nWorldPos.y * nWorldPos.y * 2.5 + 1.0;
		vec3 startPos = cameraPosition + minDist * nWorldPos;
		vec3 sampleStep = nWorldPos * rayLength;
		int sampleCount = int(min(planeDifference / rayLength, 16) + dither);

		if (maxDist >= 0.0 && sampleCount > 0) {
			float cloud = 0.0;
			float cloudAlpha = 0.0;
			float cloudLighting = 0.0;

			//Scattering variables
			float VoU = dot(nViewPos, upVec);
			float VoL = dot(nViewPos, lightVec);
			float halfVoL = mix(abs(VoL) * 0.8, VoL, shadowFade) * 0.5 + 0.5;
			float halfVoLSqr = halfVoL * halfVoL;
			float scattering = pow6(halfVoL);
			float noiseLightFactor = (2.0 - VoL * shadowFade) * cloudDensity;

			vec3 rayPos = startPos + sampleStep * dither;
			
			float maxDepth = currentDepth;
			float minimalNoise = 0.25 + dither * 0.25;
			float sampleTotalLength = minDist + rayLength * dither;

			vec2 wind = vec2(frameTimeCounter * VC_SPEED * 0.0005, sin(frameTimeCounter * VC_SPEED * 0.001) * 0.005) * cloudHeight * 0.005;

			#ifdef AURORA
			float visibilityMultiplier = pow8(1.0 - sunVisibility) * (1.0 - wetness) * caveFactor * AURORA_BRIGHTNESS;
			float auroraVisibility = 0.0;

			#ifdef AURORA_FULL_MOON_VISIBILITY
			auroraVisibility = mix(auroraVisibility, 1.0, float(moonPhase == 0));
			#endif

			#ifdef AURORA_COLD_BIOME_VISIBILITY
			auroraVisibility = mix(auroraVisibility, 1.0, isSnowy);
			#endif

			#ifdef AURORA_ALWAYS_VISIBLE
			auroraVisibility = 1.0;
			#endif

			auroraVisibility *= visibilityMultiplier;
			#endif

			//Ray marcher
			for (int i = 0; i < sampleCount; i++, rayPos += sampleStep, sampleTotalLength += rayLength) {
				if (cloudAlpha > 0.99 || (sampleTotalLength > length(viewPos) && z1 < 1.0)) break;

                vec3 worldPos = rayPos - cameraPosition;

				float shadowSample = 1.0;

				#ifdef VC_SHADOWS
				shadowSample = texture2DShadow(shadowtex1, ToShadow(worldPos));
				#endif

				//Indoor leak prevention
				if (eyeBrightnessSmooth.y < 200.0 && length(worldPos) < shadowDistance) {
					#ifndef VC_SHADOWS
					shadowSample = texture2DShadow(shadowtex1, ToShadow(worldPos));
					#endif
					if (shadowSample == 0.0) break;
				}

				float noise = 0.0;
				float rayDistance = length(worldPos.xz) * 0.085;
				float attenuation = smoothstep(cloudHeight, cloudTop, rayPos.y);

				getCloudSample(rayPos.xz, wind, attenuation, noise);

				float sampleLighting = pow(attenuation, 0.85 * halfVoLSqr + 0.85) * 0.75 + 0.25;
					  sampleLighting *= 1.0 - pow(noise, noiseLightFactor);
					  sampleLighting *= mix(1.0, 0.25 + shadowSample * 0.75, shadowLength);

				cloudLighting = mix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));
				cloud = mix(cloud, 1.0, noise);
				noise *= pow16(smoothstep(mix(VC_DISTANCE, 300, wetness), 16.0, rayDistance)); //Fog
				cloudAlpha = mix(cloudAlpha, 1.0, noise);

                float lightning = min(lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 256.0) * lightningBoltPosition.w * 4.0, 1.0);
				cloudLighting = mix(cloudLighting, pow(sampleLighting, 0.25) * 6.0, lightning);

				//gbuffers_water cloud discard check
				if (noise > minimalNoise && currentDepth == maxDepth) {
					currentDepth = sampleTotalLength;
				}
			}

			//Final color calculations
            float morningEveningFactor = mix(1.0, 0.66, sqrt(sunVisibility) * (1.0 - timeBrightnessSqrt));

			vec3 cloudAmbientColor = mix(ambientCol, atmosphereColor * atmosphereColor, 0.5 * sunVisibility);
                 cloudAmbientColor *= 0.35 + sunVisibility * sunVisibility * (0.2 - wetness * 0.2);
			vec3 cloudLightColor = mix(lightCol, mix(lightCol, atmosphereColor * 2.0, 0.3 * (sunVisibility + timeBrightness)) * atmosphereColor * 2.0, sunVisibility);
                 cloudLightColor *= (1.25 + scattering) * morningEveningFactor;
			vec3 cloudColor = mix(cloudAmbientColor, cloudLightColor, cloudLighting);

			#ifdef AURORA
			cloudColor = mix(cloudColor, vec3(0.4, 2.5, 0.9) * auroraVisibility, pow2(cloudLighting) * auroraVisibility * 0.125);
			#endif

			float opacity = clamp(mix(0.99, VC_OPACITY, float(z1 == 1.0 && cameraPosition.y < cloudHeight)), 0.0, 1.0 - wetness * 0.5);

			vc = vec4(cloudColor, cloudAlpha * opacity) * visibility;
		}
	}
}
#endif

#ifdef END_CLOUDY_FOG
void getEndCloudSample(vec2 rayPos, vec2 wind, float attenuation, inout float noise) {
	rayPos *= 0.00025;

	float noiseBase = texture2D(noisetex, rayPos + 0.5 + wind * 0.5).g;
		  noiseBase = pow2(1.0 - noiseBase) * 0.5 + 0.25;

	float detailZ = floor(attenuation * VF_END_THICKNESS) * 0.05;
	float noiseDetailA = texture2D(noisetex, rayPos * 1.5 - wind + detailZ).b;
	float noiseDetailB = texture2D(noisetex, rayPos * 1.5 - wind + detailZ + 0.05).b;
	float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * VF_END_THICKNESS));

	float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.14 : 8.0);
		  noiseCoverage *= noiseCoverage * 8.0;
	
	noise = mix(noiseBase, noiseDetail, 0.05 * int(noiseBase > 0.0)) * 22.0 - noiseCoverage;
	noise = max(noise - VF_END_AMOUNT, 0.0) * 0.75;
	noise /= sqrt(noise * noise + 0.25);
}

void computeEndVolumetricClouds(inout vec4 vc, in vec3 atmosphereColor, float z1, float dither, inout float currentDepth) {
	//Total visibility
	float visibility = int(z1 > 0.56);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Positions
		vec3 viewPos = ToView(vec3(texCoord, z1));
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
			float VoL = dot(nViewPos, sunVec);
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
				if (cloudAlpha > 0.99 || (sampleTotalLength > length(viewPos) && z1 < 1.0)) break;

                vec3 worldPos = rayPos - cameraPosition;

				float shadow1 = clamp(texture2DShadow(shadowtex1, ToShadow(worldPos)), 0.0, 1.0);

				float noise = 0.0;
				float rayDistance = length(worldPos.xz) * 0.1;
				float attenuation = smoothstep(VF_END_HEIGHT, cloudTop, rayPos.y);

				getEndCloudSample(rayPos.xz, wind, attenuation, noise);

				float sampleLighting = pow(attenuation, 0.9 + halfVoL * 1.1) * 1.25 + 0.25;
					  sampleLighting *= 1.0 - pow(noise, noiseLightFactor);

				cloudLighting = mix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));
				if (rayDistance < shadowDistance * 0.1) noise *= shadow1;
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
#endif