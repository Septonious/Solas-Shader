float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

#ifdef VC
void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float thickness, inout float density, inout float detail, inout float height) {
	int worldDayInterpolated = int((worldDay * 24000 + worldTime) / 24000);
	float dayAmountFactor = abs(worldDayInterpolated % 7 / 2 - 0.5) * 0.5;
	float dayDensityFactor = abs(worldDayInterpolated % 9 / 4 - worldDayInterpolated % 2);
	float dayFrequencyFactor = 1.0 + abs(worldDayInterpolated % 6 / 4 - worldDayInterpolated % 2) * 0.4;

	amount = mix(amount, 11.5, wetness) - dayAmountFactor;
	thickness += dayFrequencyFactor - 0.75;
	density += dayDensityFactor;
	frequency *= dayFrequencyFactor;
}

void getCloudSample(vec2 rayPos, vec2 wind, float attenuation, float amount, float frequency, float thickness, float density, float detail, inout float noise) {
	rayPos *= 0.0002 * frequency;

	float deformNoise = clamp(texture2D(noisetex, rayPos * 0.1 + wind * 0.25).g * 3.0, 0.0, 1.0);
	float noiseSample = texture2D(noisetex, rayPos * 0.5 + wind * 0.5).r;
	float noiseBase = (1.0 - noiseSample) * 0.35 + 0.25 + wetness * 0.1;

	amount *= 0.7 + deformNoise * 0.3;
	density *= 3.0 - pow3(deformNoise) * 2.0;
	detail *= 0.75 + deformNoise * 0.25;

	float detailZ = floor(attenuation * thickness) * 0.05;
	float noiseDetailA = texture2D(noisetex, rayPos - wind + detailZ).b;
	float noiseDetailB = texture2D(noisetex, rayPos - wind + detailZ + 0.05).b;
	float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * thickness));

	float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.1 : 8.0);
		  noiseCoverage *= noiseCoverage * (VC_ATTENUATION + wetness * 1.5);
	
	noise = mix(noiseBase, noiseDetail, detail * mix(0.05, 0.025, min(cameraPosition.y * 0.0025, 1.0)) * int(noiseBase > 0.0)) * 22.0 - noiseCoverage;
	noise = max(noise - amount, 0.0) * (density * 0.25);
	noise /= sqrt(noise * noise + 0.25);
}

void computeVolumetricClouds(inout vec4 vc, in vec3 atmosphereColor, float z1, float dither, inout float currentDepth) {
	//Total visibility
	float visibility = caveFactor * int(0.56 < z1);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (0 < visibility) {
		//Positions
		vec3 viewPos = ToView(vec3(texCoord, z1));
		vec3 nViewPos = normalize(viewPos);
		vec3 nWorldPos = normalize(ToWorld(viewPos));

		#ifdef DISTANT_HORIZONS
		float dhZ = texture2D(dhDepthTex0, texCoord).r;
		vec4 dhScreenPos = vec4(texCoord, dhZ, 1.0);
		vec4 dhViewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
			 dhViewPos /= dhViewPos.w;
		#endif

		//Cloud parameters
		float speed = VC_SPEED;
		float amount = VC_AMOUNT;
		float frequency = VC_FREQUENCY;
		float thickness = VC_THICKNESS;
		float density = VC_DENSITY;
		float detail = VC_DETAIL;
		float height = VC_HEIGHT;

		getDynamicWeather(speed, amount, frequency, thickness, density, detail, height);

		//Setting the ray marcher
		float cloudTop = height + thickness * 10.0;
		float lowerPlane = (height - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (cloudTop - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = max(lowerPlane, upperPlane);

		float planeDifference = maxDist - minDist;
		#ifdef DISTANT_HORIZONS
		float rayLength = thickness * 8.0;
			  rayLength /= nWorldPos.y * nWorldPos.y * 8.0 + 1.0;
		#else
		float rayLength = thickness * 5.0;
			  rayLength /= nWorldPos.y * nWorldPos.y * 5.0 + 1.0;
		#endif
		vec3 startPos = cameraPosition + minDist * nWorldPos;
		vec3 sampleStep = nWorldPos * rayLength;
		int sampleCount = int(min(planeDifference / rayLength, 24) + dither);

		if (0 < maxDist && 0 < sampleCount) {
			float cloud = 0.0;
			float cloudAlpha = 0.0;
			float cloudLighting = 0.0;

			//Scattering variables
			vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
			float VoU = dot(nViewPos, upVec);
			float VoL = dot(nViewPos, lightVec);
			float halfVoL = mix(abs(VoL) * 0.8, VoL, shadowFade) * 0.5 + 0.5;
			float halfVoLSqr = halfVoL * halfVoL;
			float scattering = pow24(halfVoL);
			float noiseLightFactor = (2.0 - VoL * shadowFade) * density;
			float lightning = 0.0;

			vec3 rayPos = startPos + sampleStep * dither;
			
			float maxDepth = currentDepth;
			float minimalNoise = 0.25 + dither * 0.25;
			float sampleTotalLength = minDist + rayLength * dither;

			vec2 wind = vec2(frameTimeCounter * speed * 0.005, sin(frameTimeCounter * speed * 0.1) * 0.01) * speed * 0.1;

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
				if (0.99 < cloudAlpha || (length(viewPos) < sampleTotalLength && z1 < 1.0)) break;

				#ifdef DISTANT_HORIZONS
				if ((length(dhViewPos.xyz) < sampleTotalLength && dhZ < 1.0)) break;
				#endif

                vec3 worldPos = rayPos - cameraPosition;
				float rayDistance = length(worldPos.xz) * 0.085;

				#ifndef DISTANT_HORIZONS
				float fog = pow16(smoothstep(mix(VC_DISTANCE, 300, wetness), 16.0, rayDistance)); //Fog
				#else
				float fog = pow16(smoothstep(mix(VC_DISTANCE * 2.0, 300, wetness), 16.0, rayDistance)); //Fog
				#endif

				if (fog < 0.01) break;

				#ifdef VC_LIGHTRAYS
				float shadow1 = clamp(texture2DShadow(shadowtex1, ToShadow(worldPos)), 0.0, 1.0);
				#else
				float shadow1 = 1.0;

				//Indoor leak prevention
				if (eyeBrightnessSmooth.y < 220.0 && length(worldPos) < shadowDistance) {
					shadow1 = clamp(texture2DShadow(shadowtex1, ToShadow(worldPos)), 0.0, 1.0);

					if (shadow1 <= 0.0) break;
				}
				#endif

				float noise = 0.0;
				float attenuation = smoothstep(height, cloudTop, rayPos.y);

				getCloudSample(rayPos.xz, wind, attenuation, amount, frequency, thickness, density, detail, noise);

				float sampleLighting = pow(attenuation, 0.9 - halfVoLSqr * 0.2);
					  sampleLighting *= 1.0 - pow(noise, noiseLightFactor) * 0.9 + 0.1;
				#ifdef VC_LIGHTRAYS
					  sampleLighting *= mix(1.0, 0.25 + shadow1 * 0.75, float(length(worldPos) < shadowDistance));
				#endif

				cloudLighting = mix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));
				cloud = mix(cloud, 1.0, noise);
				noise *= fog;
				cloudAlpha = mix(cloudAlpha, 1.0, noise);

                lightning = min(lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 256.0) * lightningBoltPosition.w * 4.0, 1.0);

				//gbuffers_water cloud discard check
				if (minimalNoise < noise && currentDepth == maxDepth) {
					currentDepth = sampleTotalLength;
				}
			}

			//Final color calculations
            float morningEveningFactor = mix(1.0, 0.66, sqrt(sunVisibility) * (1.0 - timeBrightnessSqrt));

			vec3 cloudAmbientColor = mix(ambientCol, atmosphereColor * atmosphereColor, 0.4 * sunVisibility);
                 cloudAmbientColor *= 0.4 + sunVisibility * sunVisibility * (0.2 - wetness * 0.2);
			vec3 cloudLightColor = mix(lightCol, mix(lightCol, atmosphereColor * 2.25, 0.25 * (sunVisibility + timeBrightness)) * atmosphereColor * 2.25, sunVisibility);
                 cloudLightColor *= (1.0 + scattering) * morningEveningFactor;
			vec3 cloudColor = mix(cloudAmbientColor, cloudLightColor, cloudLighting) * (1.0 + lightning * 64.0);

			#ifdef AURORA
			cloudColor = mix(cloudColor, vec3(0.4, 2.5, 0.9) * auroraVisibility, pow2(cloudLighting) * auroraVisibility * 0.075);
			#endif

			float opacity = clamp(mix(VC_OPACITY, 0.99, (max(0.0, cameraPosition.y) / height)), 0.0, 1.0 - wetness * 0.5);

			#if MC_VERSION >= 12104
			opacity = mix(opacity, opacity * 0.5, isPaleGarden);
			#endif

			vc = vec4(cloudColor, cloudAlpha * opacity) * visibility;
		}
	}
}
#endif

#ifdef END_CLOUDY_FOG
void getEndCloudSample(vec2 rayPos, vec2 wind, float attenuation, inout float noise) {
	rayPos *= 0.0002;

	float noiseBase = texture2D(noisetex, rayPos + 0.5 + wind * 0.5).g;
		  noiseBase = (1.0 - noiseBase) * 0.5 + 0.25;

	float detailZ = floor(attenuation * VF_END_THICKNESS) * 0.05;
	float noiseDetailA = texture2D(noisetex, rayPos * 1.5 - wind + detailZ).b;
	float noiseDetailB = texture2D(noisetex, rayPos * 1.5 - wind + detailZ + 0.05).b;
	float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * VF_END_THICKNESS));

	float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.14 : 8.0);
		  noiseCoverage *= noiseCoverage * 8.0;
	
	noise = mix(noiseBase, noiseDetail, 0.025 * int(0 < noiseBase)) * 22.0 - noiseCoverage;
	noise = max(noise - VF_END_AMOUNT, 0.0) * 0.75;
	noise /= sqrt(noise * noise + 0.25);
}

void computeEndVolumetricClouds(inout vec4 vc, in vec3 atmosphereColor, float z1, float dither, inout float currentDepth) {
	//Total visibility
	float visibility = int(0.56 < z1);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Positions
		vec3 viewPos = ToView(vec3(texCoord, z1));
		vec3 nViewPos = normalize(viewPos);
		vec3 nWorldPos = normalize(ToWorld(viewPos));

		#ifdef DISTANT_HORIZONS
		float dhZ = texture2D(dhDepthTex0, texCoord).r;
		vec4 dhScreenPos = vec4(texCoord, dhZ, 1.0);
		vec4 dhViewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
			 dhViewPos /= dhViewPos.w;
		#endif

		//Setting the ray marcher
		float dragonBattle = 1.0;

		#if MC_VERSION <= 12104
			 dragonBattle = gl_Fog.start / far;
		#endif

		float cloudTop = VF_END_HEIGHT + VF_END_THICKNESS * 10.0 * (1.75 - dragonBattle * 0.75);
		float lowerPlane = (VF_END_HEIGHT - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (cloudTop - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = max(lowerPlane, upperPlane);

		float planeDifference = maxDist - minDist;
		float rayLength = VF_END_THICKNESS * 5.0 * (1.75 - dragonBattle * 0.75);
			  rayLength /= nWorldPos.y * nWorldPos.y * 3.0 + 1.0;
		vec3 startPos = cameraPosition + minDist * nWorldPos;
		vec3 sampleStep = nWorldPos * rayLength;
		int sampleCount = int(min(planeDifference / rayLength, 24) + dither);

		if (maxDist >= 0.0 && sampleCount > 0) {
			float cloud = 0.0;
			float cloudAlpha = 0.0;
			float cloudLighting = 0.0;

			//Scattering variables
			float VoU = dot(nViewPos, upVec);
			float VoL = dot(nViewPos, sunVec);
			float halfVoLSqrt = VoL * 0.5 + 0.5;
			float halfVoL = halfVoLSqrt * halfVoLSqrt;
			float scattering = pow6(halfVoLSqrt);
			float noiseLightFactor = (2.0 - VoL) * 5.0;

			vec3 rayPos = startPos + sampleStep * dither;
			
			float maxDepth = currentDepth;
			float minimalNoise = 0.25 + dither * 0.25;
			float sampleTotalLength = minDist + rayLength * dither;

			vec2 wind = vec2(frameTimeCounter * VC_SPEED * 0.0005, sin(frameTimeCounter * VC_SPEED * 0.001) * 0.005) * VF_END_HEIGHT * 0.1 * (4.0 - dragonBattle * 3.0);

			//Ray marcher
			for (int i = 0; i < sampleCount; i++, rayPos += sampleStep, sampleTotalLength += rayLength) {
				if (0.99 < cloudAlpha || (length(viewPos) < sampleTotalLength && z1 < 1.0)) break;

				#ifdef DISTANT_HORIZONS
				if ((length(dhViewPos.xyz) < sampleTotalLength && dhZ < 1.0)) break;
				#endif

                vec3 worldPos = rayPos - cameraPosition;

				float shadow1 = clamp(texture2DShadow(shadowtex1, ToShadow(worldPos)), 0.0, 1.0);

				float noise = 0.0;
				float rayDistance = length(worldPos.xz) * 0.1;
				float attenuation = smoothstep(VF_END_HEIGHT, cloudTop, rayPos.y);

				getEndCloudSample(rayPos.xz * 1.5, wind, attenuation, noise);

				float sampleLighting = pow(attenuation, 0.9 + halfVoL * 1.1) * 1.25 + 0.25;
					  sampleLighting *= 1.0 - pow(noise, noiseLightFactor);

				cloudLighting = mix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));
				if (rayDistance < shadowDistance * 0.1) noise *= shadow1;
				cloud = mix(cloud, 1.0, noise);
				noise *= pow24(smoothstep(1024.0, 8.0, rayDistance)); //Fog
				cloudAlpha = mix(cloudAlpha, 1.0, noise);

				//gbuffers_water cloud discard check
				if (noise > minimalNoise && currentDepth == maxDepth) {
					currentDepth = sampleTotalLength;
				}
			}

			//Final color calculations
			vec3 cloudColor = mix(endAmbientCol * 0.1, endLightCol * 0.2, cloudLighting) * (1.0 + scattering);

			vc = vec4(cloudColor, cloudAlpha * VF_END_OPACITY) * visibility;
		}
	}
}
#endif