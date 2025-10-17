float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

#ifdef VOLUMETRIC_CLOUDS
void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float thickness, inout float density, inout float detail, inout float height, inout float scale) {
	#ifdef VC_DYNAMIC_WEATHER
	int day = int((worldDay * 24000 + worldTime) / 24000);
	float dayAmountFactor = abs(day % 7 / 2 - 0.5) * 0.5;
	float dayDensityFactor = abs(day % 9 / 4 - day % 2);
	float dayFrequencyFactor = 1.0 + abs(day % 6 / 4 - day % 2) * 0.4;
    float dayScaleFactor = (day % 5 - day % 8 + day % 3) * 0.5;
	float dayHeightFactor = day % 5 + day % 18 + day % 27 - day % 33 - 10;
	#endif

	amount = mix(amount, 10.50, wetness);

	#ifdef VC_DYNAMIC_WEATHER
	amount -= dayAmountFactor;
	thickness += dayFrequencyFactor - 0.75;
	density += dayDensityFactor;
    scale += dayScaleFactor;
	height += dayHeightFactor;
	#endif
}

void getCloudSample(vec2 rayPos, vec2 wind, float attenuation, float amount, float frequency, float thickness, float density, float detail, inout float noise) {
	rayPos *= 0.0035 * frequency;

	float worleyNoise = (1.0 - texture2D(noisetex, rayPos.xy + wind * 0.5).g) * 0.4 + 0.25;
	float perlinNoise = texture2D(noisetex, rayPos.xy + wind * 0.5).r;
	float noiseBase = perlinNoise * 0.6 + worleyNoise * 0.4;

	float detailZ = floor(attenuation * thickness) * 0.05;
	float noiseDetailA = texture2D(noisetex, rayPos - wind + detailZ).b;
	float noiseDetailB = texture2D(noisetex, rayPos - wind + detailZ + 0.05).b;
	float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * thickness));

	float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.1 : 8.0);
		  noiseCoverage *= noiseCoverage * (VC_ATTENUATION + wetness * 1.5);
	
	noise = mix(noiseBase, noiseDetail, detail * 0.05) * 22.0 - noiseCoverage;
	noise = max(noise - amount, 0.0) * (density * 0.25);
	noise /= sqrt(noise * noise + 0.25);
}

void computeVolumetricClouds(inout vec4 vc, in vec3 atmosphereColor, float z0, float dither, inout float currentDepth) {
	//Total visibility
	float visibility = caveFactor * int(0.56 < z0);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Positions
		vec3 viewPos = ToView(vec3(texCoord, z0));
		vec3 nViewPos = normalize(viewPos);
		vec3 nWorldPos = normalize(ToWorld(viewPos));

		float lViewPos = length(viewPos);

		#ifdef DISTANT_HORIZONS
		float dhZ = texture2D(dhDepthTex0, texCoord).r;
		vec4 dhScreenPos = vec4(texCoord, dhZ, 1.0);
		vec4 dhViewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
			 dhViewPos /= dhViewPos.w;
		float lDhViewPos = length(dhViewPos.xyz);
		#endif

		//Cloud parameters
		float speed = VC_SPEED;
		float amount = VC_AMOUNT;
		float frequency = VC_FREQUENCY;
		float thickness = VC_THICKNESS;
		float density = VC_DENSITY;
		float detail = VC_DETAIL;
		float height = VC_HEIGHT;
        float scale = VC_SCALE;
        float distance = VC_DISTANCE;

		getDynamicWeather(speed, amount, frequency, thickness, density, detail, height, scale);

        #ifdef DISTANT_HORIZONS
        distance *= 2.0;
        #endif

		//Setting the ray marcher
		float cloudTop = height + thickness * scale;
		float lowerPlane = (height - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (cloudTop - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = max(lowerPlane, upperPlane);

		float planeDifference = maxDist - minDist;
		vec3 startPos = cameraPosition + minDist * nWorldPos;

        #ifndef DISTANT_HORIZONS
		float rayLength = thickness * 4.0;
			  rayLength /= nWorldPos.y * nWorldPos.y * 4.0 + 1.0;
        #else
		float rayLength = thickness * 6.0;
			  rayLength /= nWorldPos.y * nWorldPos.y * 6.0 + 1.0;
        #endif

		vec3 rayIncrement = nWorldPos * rayLength;
		int sampleCount = min(int(planeDifference / rayLength + 1), 6 + VC_DISTANCE / 1000);

		if (maxDist > 0 && sampleCount > 0) {
			float cloud = 0.0;
			float cloudAlpha = 0.0;
			float cloudLighting = 0.0;

			//Variables
			vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
			float VoU = dot(nViewPos, upVec);
			float VoL = dot(nViewPos, lightVec);
			float halfVoL = mix(abs(VoL), VoL, shadowFade) * 0.5 + 0.5;
			float halfVoLSqr = halfVoL * halfVoL;
			float scattering = pow12(halfVoL);
			float noiseLightFactor = (2.0 - VoL * shadowFade) * density;
			float heightFactor = 1.0 - clamp(cameraPosition.y / cloudTop, 0.0, 1.0);

			vec3 rayPos = startPos + rayIncrement * dither;
			
			float maxDepth = currentDepth;
			float sampleTotalLength = minDist + rayLength * dither;
			float fogDistance = 10.0 / max(abs(float(height) - 72.0), 56.0);

			float time = (worldTime + int(5 + mod(worldDay, 100)) * 24000) * 0.05;
			vec2 wind = vec2(time * speed * 0.005, sin(time * speed * 0.1) * 0.01) * speed * 0.1;

			//Ray marcher
			for (int i = 0; i < sampleCount; i++, rayPos += rayIncrement, sampleTotalLength += rayLength) {
				if (cloudAlpha > 0.99 || (lViewPos < sampleTotalLength && z0 < 1.0)) break;

				#ifdef DISTANT_HORIZONS
				if ((lDhViewPos < sampleTotalLength && dhZ < 1.0)) break;
				#endif

                vec3 worldPos = rayPos - cameraPosition;
				float lWorldPos = length(worldPos.xz);

				if (lWorldPos > distance) break;

				//Indoor leak prevention
				if (eyeBrightnessSmooth.y < 210.0 && cameraPosition.y > height - 50.0 && lWorldPos < shadowDistance) {
					if (texture2DShadow(shadowtex1, ToShadow(worldPos)) <= 0.0) break;
				}

				float noise = 0.0;
				float attenuation = smoothstep(height, cloudTop, rayPos.y);

				amount += max(0.0, heightFactor - lWorldPos * 0.0075);
				getCloudSample(rayPos.xz / scale, wind, attenuation, amount, frequency, thickness, density, detail, noise);

                float lightning = min(lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 512.0) * lightningBoltPosition.w * 32.0, 1.0);
				float sampleLighting = pow(attenuation, 1.0 + scattering);
					  sampleLighting *= 1.0 - pow(noise, noiseLightFactor) * (0.85 - lightning * 0.85) + lightning * 128.0;
					  sampleLighting = clamp(sampleLighting, 0.0, 1.0);

				cloudLighting = mix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));
				cloud = mix(cloud, 1.0, noise);
				noise *= pow6(smoothstep(mix(distance * 0.1, 300, wetness), 16.0, lWorldPos * fogDistance));
				cloudAlpha = mix(cloudAlpha, 1.0, noise);

				//gbuffers_water cloud discard check
				if (currentDepth == maxDepth && cloud > 0.5) {
					currentDepth = sampleTotalLength;
				}
			}

			//Final color calculations
            #ifdef AURORA_LIGHTING_INFLUENCE
            float kpIndex = abs(worldDay % 9 - worldDay % 4); //Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
            float auroraVisibility = pow6(1.0 - sunVisibility) * (1.0 - wetness) * caveFactor * AURORA_BRIGHTNESS;

            #ifdef OVERWORLD
            #ifdef AURORA_FULL_MOON_VISIBILITY
            kpIndex += float(moonPhase == 0) * 3;
            #endif

            #ifdef AURORA_COLD_BIOME_VISIBILITY
            kpIndex += isSnowy * 5;
            #endif
            #endif

            #ifdef AURORA_ALWAYS_VISIBLE
            auroraVisibility = 1.0;
            kpIndex = 9.0;
            #endif

            kpIndex = clamp(kpIndex, 0.0, 9.0) / 9.0;
            auroraVisibility *= kpIndex;
            #endif

			float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
			cloudLighting = cloudLighting * shadowFade + pow8(1.0 - cloudLighting) * pow3(VoS) * (1.0 - shadowFade) * 0.75;

			vec3 nSkyColor = normalize(skyColor + 0.0001);
            vec3 cloudAmbientColor = mix(atmosphereColor * atmosphereColor * 0.5, 
									 mix(ambientCol, atmosphereColor * nSkyColor * 0.5, 0.2 + timeBrightnessSqrt * 0.3 + isSpecificBiome * 0.4),
									 sunVisibility * (1.0 - wetness));
            vec3 cloudLightColor = mix(lightCol, lightCol * nSkyColor * 2.0, timeBrightnessSqrt * (0.5 - wetness * 0.5));
				 cloudLightColor *= 0.5 + timeBrightnessSqrt * 0.5 + moonVisibility * 0.5;
				 cloudLightColor *= 1.0 + scattering * shadowFade * 5.0;
			vec3 cloudColor = mix(cloudAmbientColor, cloudLightColor, cloudLighting) * mix(vec3(1.0), biomeColor, isSpecificBiome * sunVisibility);
			     cloudColor = mix(cloudColor, atmosphereColor * length(cloudColor) * 0.5, wetness * 0.6);
                 #ifdef AURORA_LIGHTING_INFLUENCE
                 cloudColor = mix(cloudColor, vec3(0.4, 1.5, 0.6), auroraVisibility * pow3(cloudLighting) * 0.2);
                 #endif

			float opacity = clamp(mix(VC_OPACITY, 1.00, (max(0.0, cameraPosition.y) / height)), 0.0, 1.0 - wetness * 0.5);

			#if MC_VERSION >= 12104
			opacity = mix(opacity, opacity * 0.5, isPaleGarden);
			#endif

			vc = vec4(cloudColor, cloudAlpha * opacity) * visibility;
		}
	}
}
#endif

#ifdef END_DISK
#if MC_VERSION >= 12100 && defined END_FLASHES
float endFlashPosToPoint(vec3 flashPosition, vec3 worldPos) {
    vec3 flashPos = mat3(gbufferModelViewInverse) * flashPosition;
    vec2 flashCoord = flashPos.xz / (flashPos.y + length(flashPos));
    vec2 planeCoord = worldPos.xz / (length(worldPos) + worldPos.y) - flashCoord;
    float flashPoint = 1.0 - clamp(length(planeCoord), 0.0, 1.0);

    return flashPoint;
}
#endif

float getProtoplanetaryDisk(vec2 coord){
	float whirl = -5;
	float arms = 5;

    coord = vec2(atan(coord.y, coord.x) + frameTimeCounter * 0.01, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow4(1.0 - coord.y) * 1.0;
    float spiral = sin((coord.x + sqrt(coord.y) * whirl) * arms) + center - coord.y;

    return min(spiral, 1);
}

void getEndCloudSample(vec2 rayPos, vec2 wind, float attenuation, inout float noise) {
	rayPos *= 0.00035;

	float worleyNoise = (1.0 - texture2D(noisetex, rayPos.xy + wind * 0.5).g) * 0.4 + 0.25;
	float perlinNoise = texture2D(noisetex, rayPos.xy + wind * 0.5).r;
	float noiseBase = perlinNoise * 0.6 + worleyNoise * 0.4;

	float detailZ = floor(attenuation * END_DISK_THICKNESS) * 0.05;
	float noiseDetailA = texture2D(noisetex, rayPos * 0.5 - wind + detailZ).b;
	float noiseDetailB = texture2D(noisetex, rayPos * 0.5 - wind + detailZ + 0.05).b;
	float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * END_DISK_THICKNESS));

	float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.14 : 5.0);
		  noiseCoverage *= noiseCoverage * 4.0;
	
	noise = mix(noiseBase, noiseDetail, 0.025 * int(0 < noiseBase)) * 22.0 - noiseCoverage;
	noise = max(noise - END_DISK_AMOUNT - 1.0 + getProtoplanetaryDisk(rayPos), 0.0);
	noise /= sqrt(noise * noise + 0.25);
}

void computeEndVolumetricClouds(inout vec4 vc, in vec3 atmosphereColor, float z0, float dither, inout float currentDepth) {
	//Total visibility
	float visibility = int(0.56 < z0);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Positions
		vec3 viewPos = ToView(vec3(texCoord, z0));
		vec3 nViewPos = normalize(viewPos);
        vec3 worldPos = ToWorld(viewPos);
		vec3 nWorldPos = normalize(worldPos);
		vec3 worldSunVec = normalize(ToWorld(sunVec * 10000000.0));

		#if MC_VERSION >= 12100 && defined END_FLASHES
		vec3 worldEndFlashPosition = normalize(ToWorld(endFlashPosition * 10000000.0));
		#endif

		#ifdef DISTANT_HORIZONS
		float dhZ = texture2D(dhDepthTex0, texCoord).r;
		vec4 dhScreenPos = vec4(texCoord, dhZ, 1.0);
		vec4 dhViewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
			 dhViewPos /= dhViewPos.w;
		#endif

		//Setting the ray marcher
		float cloudTop = END_DISK_HEIGHT + END_DISK_THICKNESS * 10.0;
		float lowerPlane = (END_DISK_HEIGHT - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (cloudTop - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = max(lowerPlane, upperPlane);

		float planeDifference = maxDist - minDist;
		float rayLength = END_DISK_THICKNESS * 8.0;
			  rayLength /= nWorldPos.y * nWorldPos.y * 8.0 + 1.0;
		vec3 startPos = cameraPosition + minDist * nWorldPos;
		vec3 sampleStep = nWorldPos * rayLength;
		int sampleCount = int(min(planeDifference / rayLength, 64) + dither);

		if (maxDist >= 0.0 && sampleCount > 0) {
			float cloud = 0.0;
			float cloudAlpha = 0.0;
			float cloudLighting = 0.0;

			//Scattering variables
			float VoU = dot(nViewPos, upVec);
			float VoS = dot(nViewPos, sunVec);

			float halfVoLSqrt = VoS * 0.5 + 0.5;
			float halfVoL = halfVoLSqrt * halfVoLSqrt;
			float scattering = pow8(halfVoLSqrt);
			float noiseLightFactor = (2.0 - VoS) * 16.0;

			vec3 rayPos = startPos + sampleStep * dither;
			
			float maxDepth = currentDepth;
			float minimalNoise = 0.25 + dither * 0.25;
			float sampleTotalLength = minDist + rayLength * dither;

			vec2 wind = vec2(frameTimeCounter * 0.005, sin(frameTimeCounter * 0.1) * 0.01) * 0.1;

			//Ray marcher
			for (int i = 0; i < sampleCount; i++, rayPos += sampleStep, sampleTotalLength += rayLength) {
				if (0.99 < cloudAlpha || (length(viewPos) < sampleTotalLength && z0 < 1.0)) break;

				#ifdef DISTANT_HORIZONS
				if ((length(dhViewPos.xyz) < sampleTotalLength && dhZ < 1.0)) break;
				#endif

                vec3 worldPos = rayPos - cameraPosition;

				float shadow1 = clamp(texture2DShadow(shadowtex1, ToShadow(worldPos)), 0.0, 1.0);

				float noise = 0.0;
				float lightingNoise = 0.0;
				float rayDistance = length(worldPos.xz) * 0.1;
				float attenuation = smoothstep(END_DISK_HEIGHT, cloudTop, rayPos.y);

				getEndCloudSample(rayPos.xz, wind, attenuation, noise);

				#if MC_VERSION >= 12100 && defined END_FLASHES
				getEndCloudSample(rayPos.xz + worldSunVec.xz * 32.0 + worldEndFlashPosition.xz * 24.0 * endFlashIntensity, wind, attenuation + worldSunVec.y * 0.15, lightingNoise);
				#else
				getEndCloudSample(rayPos.xz + worldSunVec.xz * 32.0, wind, attenuation + worldSunVec.y * 0.15, lightingNoise);
				#endif

				float sampleLighting = 0.05 + clamp(noise - lightingNoise * (0.9 - scattering * 0.15), 0.0, 0.95) * (1.5 + scattering);
					  sampleLighting *= 1.0 - noise * 0.75;
					  sampleLighting = clamp(sampleLighting, 0.0, 1.0);

				cloudLighting = mix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));
				if (rayDistance < shadowDistance * 0.1) noise *= shadow1;
				cloud = mix(cloud, 1.0, noise);
				noise *= pow8(smoothstep(4000.0, 8.0, rayDistance)); //Fog
				cloudAlpha = mix(cloudAlpha, 1.0, noise);

				//gbuffers_water cloud discard check
				if (noise > minimalNoise && currentDepth == maxDepth) {
					currentDepth = sampleTotalLength;
				}
			}

			//Final color calculations
            vec3 cloudColor = vec3(0.95, 1.0, 0.5) * endLightCol;
            #if MC_VERSION >= 12100 && defined END_FLASHES
            float endFlashPoint = endFlashPosToPoint(endFlashPosition, worldPos);
                 cloudColor = mix(cloudColor, endFlashCol * (1.0 + endFlashPoint * endFlashPoint * 2.0), endFlashPoint * endFlashIntensity * 0.5);
            #endif
			     cloudColor *= cloudLighting * 0.35;

			vc = vec4(cloudColor, cloudAlpha * END_DISK_OPACITY) * visibility;
		}
	}
}
#endif