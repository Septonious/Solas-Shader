#ifdef VOLUMETRIC_CLOUDS
void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float thickness, inout float density, inout float detail, inout float height, inout float scale) {
	#ifdef VC_DYNAMIC_WEATHER
	float day = (worldDay * 24000 + worldTime) / 24000;
    float sinDay05 = sin(day * 0.5);
    float cosDay075 = cos(day * 0.75);
    float cosDay15 = cos(day * 1.5);
    float sinDay2 = sin(day * 2.0);
    float waveFunction = sinDay05 * cosDay075 + sinDay2 * 0.25 - cosDay15 * 0.75;

    amount += waveFunction * (0.5 + cosDay075 * 0.5) * 0.5;
    height += waveFunction * sinDay2 * 75.0;
    scale += waveFunction * cosDay075;
    thickness += waveFunction * waveFunction * cosDay15;
    density += waveFunction * sinDay05;
	#endif

	#if MC_VERSION >= 12104
    amount -= isPaleGarden;
	#endif

    amount = fmix(amount, 10.25, wetness);
}

float CloudSampleBaseWorley(vec2 coord) {
	float noiseBase = texture2D(noisetex, coord).g;
	      noiseBase = pow(1.0 - noiseBase, 1.5) * 0.5 + 0.2;

	return noiseBase;
}

float CloudSampleDetail(vec2 coord, float sampleAltitude, float thickness) {
	float detailZ = floor(sampleAltitude * float(thickness)) * 0.04;
	float detailFrac = fract(sampleAltitude * float(thickness));

	float noiseDetailLow = texture2D(noisetex, coord.xy + detailZ).b;
	float noiseDetailHigh = texture2D(noisetex, coord.xy + detailZ + 0.04).b;

	float noiseDetail = fmix(noiseDetailLow, noiseDetailHigh, detailFrac);

	return noiseDetail;
}

float CloudCoverageDefault(float sampleAltitude, float amount) {
	float noiseCoverage = abs(sampleAltitude - 0.125);

	noiseCoverage *= sampleAltitude > 0.125 ? (2.14 - amount * 0.1) : 8.0;
	noiseCoverage = noiseCoverage * noiseCoverage * 4.0;

	return noiseCoverage;
}

float CloudApplyDensity(float noise, float density) {
	noise *= density * 0.125;
	noise *= (1.0 - 0.75 * wetness);
	noise = noise / sqrt(noise * noise + 0.5);

	return noise;
}

float CloudCombineDefault(float noiseBase, float noiseDetail, float noiseCoverage, float amount, float density) {
	float noise = fmix(noiseBase, noiseDetail, 0.0476 * VC_DETAIL) * 21.0;

	noise = fmix(noise - noiseCoverage, 21.0 - noiseCoverage * 2.5, 0.33 * wetness);
	noise = max(noise - amount, 0.0);

	noise = CloudApplyDensity(noise, density);

	return noise;
}

float CloudSample(vec2 coord, vec2 wind, float sampleAltitude, float thickness, float frequency, float amount, float density) {
	coord *= 0.004 * frequency;

	vec2 baseCoord = coord * 0.5 + wind * 2.0;
	vec2 detailCoord = coord.xy - wind * 2.0;

	float noiseBase = CloudSampleBaseWorley(baseCoord);
	float noiseDetail = CloudSampleDetail(detailCoord, sampleAltitude, thickness);
	float noiseCoverage = CloudCoverageDefault(sampleAltitude, amount);

	float noise = CloudCombineDefault(noiseBase, noiseDetail, noiseCoverage, amount, density);
	
	return noise;
}

float CloudSampleLowDetail(vec2 coord, vec2 wind, float sampleAltitude, float thickness, float frequency, float amount, float density) {
	coord *= 0.004 * frequency;

	vec2 baseCoord = coord * 0.5 + wind * 2.0;

	float noiseBase = CloudSampleBaseWorley(baseCoord);
	float noiseCoverage = CloudCoverageDefault(sampleAltitude, amount);

	float noise = CloudCombineDefault(noiseBase, 0.0, noiseCoverage, amount, density);
	
	return noise;
}

float InvLerp(float v, float l, float h) {
	return clamp((v - l) / (h - l), 0.0, 1.0);
}

void computeVolumetricClouds(inout vec4 vc, in vec3 atmosphereColor, float z, float dither, inout float currentDepth) {
	//Total visibility
	float visibility = caveFactor * int(0.56 < z);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

    if (visibility > 0.0) {
		vec3 viewPos = ToView(vec3(texCoord, z));
		vec3 nViewPos = normalize(viewPos);
		vec3 nWorldPos = normalize(ToWorld(viewPos));
        float lViewPos = length(viewPos);

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

        int maxsampleCount = 24;

        float cloudBottom = height;
        float cloudTop = cloudBottom + thickness * scale;

        float lowerPlane = (cloudBottom - cameraPosition.y) / nWorldPos.y;
        float upperPlane = (cloudTop - cameraPosition.y) / nWorldPos.y;

        float nearestPlane = max(min(lowerPlane, upperPlane), 0.0);
        float farthestPlane = max(lowerPlane, upperPlane);

        float maxDist = currentDepth;

        if (farthestPlane > 0) {
            float planeDifference = farthestPlane - nearestPlane;

            float lengthScaling = abs(cameraPosition.y - (cloudTop + cloudBottom) * 0.5) / ((cloudTop - cloudBottom) * 0.5);
                  lengthScaling = clamp((lengthScaling - 1.0) * thickness * 0.125, 0.0, 1.0);

            float rayLength = thickness * scale / 2.0;
                  rayLength /= (4.0 * nWorldPos.y * nWorldPos.y) * lengthScaling + 1.0;

            vec3 rayIncrement = nWorldPos * rayLength;
            int sampleCount = int(min(planeDifference / rayLength, maxsampleCount) + 5);
            
            vec3 startPos = cameraPosition + nearestPlane * nWorldPos;
            vec3 rayPos = startPos + rayIncrement * dither;
            float sampleTotalLength = nearestPlane + rayLength * dither;

            float time = (worldTime + int(5 + mod(worldDay, 100)) * 24000) * 0.05;
            vec2 wind = vec2(time * speed * 0.005, sin(time * speed * 0.1) * 0.01) * speed * 0.05;

            float cloud = 0.0;
            float cloudFaded = 0.0;
            float cloudLighting = 0.0;

            float VoU = dot(nViewPos, upVec);
            float VoL = dot(nViewPos, lightVec);
            float VoS = dot(nViewPos, sunVec);

            float halfVoL = fmix(abs(VoL) * 0.8, VoL, shadowFade) * 0.5 + 0.5;
            float halfVoLSqr = halfVoL * halfVoL;
            float halfVol4 = halfVoLSqr * halfVoLSqr;
            float scattering = pow12(halfVoL);

            float viewLengthSoftMin = lViewPos - rayLength * 0.5;
            float viewLengthSoftMax = lViewPos + rayLength * 0.5;

            float distanceFade = 1.0;
            float fadeStart = 32.0 / max(FOG_DENSITY, 0.5);
            float fadeEnd = distance / max(FOG_DENSITY, 0.5);

            float xzNormalizeFactor = 10.0 / max(abs(height - 72.0), 56.0);

            vec3 worldSunVec = mat3(gbufferModelViewInverse) * normalize(lightVec * 10000.0) + gbufferModelViewInverse[3].xyz;
                 worldSunVec.xz *= 3.0;

            for (int i = 0; i < sampleCount; i++, rayPos += rayIncrement, sampleTotalLength += rayLength) {
                if (cloud > 0.99 || (viewLengthSoftMax < sampleTotalLength && z < 1.0) || sampleTotalLength > distance * 32.0) break;

                float sampleAltitude = InvLerp(rayPos.y, cloudBottom, cloudTop);
                float xzNormalizedDistance = length(rayPos.xz - cameraPosition.xz) * xzNormalizeFactor;
                vec2 cloudCoord = rayPos.xz / scale;

                float attenuation = step(cloudBottom, rayPos.y) * step(rayPos.y, cloudTop);

                float noise = CloudSample(cloudCoord, wind, sampleAltitude, thickness, frequency, amount, density);
                      noise *= attenuation;

                float lightingNoise = CloudSampleLowDetail(cloudCoord + worldSunVec.xz, wind, sampleAltitude, thickness, frequency, amount, density);
                      lightingNoise *= attenuation;

                float noiseDiff = clamp(noise - lightingNoise * 0.9, 0.0, 1.0);

                float sampleLighting = 0.125 + pow(sampleAltitude, 1.5) * 0.875;
                      sampleLighting *= 1.0 - exp(-2.0 * noiseDiff);
                      sampleLighting *= 2.0;

                float sampleFade = InvLerp(xzNormalizedDistance, fadeEnd, fadeStart);
                distanceFade *= fmix(1.0, sampleFade, noise * (1.0 - cloud));
                noise *= step(xzNormalizedDistance, fadeEnd);

                cloudLighting = fmix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));

                cloud = fmix(cloud, 1.0, noise);

                cloudFaded = fmix(cloudFaded, 1.0, noise);

                if (currentDepth == maxDist && cloud > 0.5) {
                    currentDepth = sampleTotalLength;
                }
            }

            cloudFaded *= distanceFade;

            //Final color calculations
            #ifdef AURORA_LIGHTING_INFLUENCE
            //The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
            float kpIndex = abs(worldDay % 9 - worldDay % 4);
                    kpIndex = kpIndex - int(kpIndex == 1) + int(kpIndex > 7 && worldDay % 10 == 0);
                    kpIndex = min(max(kpIndex, 0) + isSnowy, 9);

            //Total visibility of aurora based on multiple factors
            float auroraVisibility = pow6(moonVisibility) * (1.0 - wetness) * caveFactor;

            //Aurora tends to get brighter and dimmer when plasma arrives or fades away
            float pulse = clamp(cos(sin(frameTimeCounter * 0.1) * 0.3 + frameTimeCounter * 0.07), 0.0, 1.0);
            float longPulse = clamp(sin(cos(frameTimeCounter * 0.01) * 0.6 + frameTimeCounter * 0.04), -1.0, 1.0);

            kpIndex *= 1.0 + longPulse * 0.25;
            kpIndex /= 9.0;
            auroraVisibility *= kpIndex * 0.075;
            #endif

			float VoSClamped = clamp(VoS, 0.0, 1.0);
			cloudLighting = cloudLighting * shadowFade + pow8(1.0 - cloudLighting) * pow3(VoSClamped) * (1.0 - shadowFade) * 0.75;

			vec3 nSkyColor = normalize(skyColor + 0.0001);
            vec3 cloudAmbientColor = fmix(atmosphereColor * atmosphereColor * 0.5, 
									 fmix(ambientCol, atmosphereColor * nSkyColor * 0.5, 0.2 + timeBrightnessSqrt * 0.3 + isSpecificBiome * 0.4),
									 sunVisibility * (1.0 - wetness));
            vec3 cloudLightColor = fmix(lightCol, lightCol * nSkyColor * 2.0, timeBrightnessSqrt * (0.5 - wetness * 0.5));
				 cloudLightColor *= 0.5 + timeBrightnessSqrt * 0.5 + moonVisibility * 0.5;
				 cloudLightColor *= 1.0 + scattering * shadowFade * (1.0 + scattering * moonVisibility);
			vec3 cloudColor = fmix(cloudAmbientColor, cloudLightColor, cloudLighting) * fmix(vec3(1.0), biomeColor, isSpecificBiome * sunVisibility);
			     cloudColor = fmix(cloudColor, atmosphereColor * length(cloudColor) * 0.5, wetness * 0.6);
                 #ifdef AURORA_LIGHTING_INFLUENCE
                 cloudColor = fmix(cloudColor, vec3(0.05, 1.55, 0.40), clamp(auroraVisibility * cloudLighting * cloudLighting, 0.0, 0.1));
                 #endif

            float opacity = clamp(fmix(VC_OPACITY - wetness * 0.2, 1.0, (max(0.0, cameraPosition.y) / height)), 0.0, 1.0);

            #if MC_VERSION >= 12104
            opacity = fmix(opacity, opacity * 0.5, isPaleGarden);
            #endif

            cloudFaded *= cloudFaded * opacity;
            vc = vec4(cloudColor, cloudFaded * visibility);
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
	float noiseDetail = fmix(noiseDetailA, noiseDetailB, fract(attenuation * END_DISK_THICKNESS));

	float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.14 : 5.0);
		  noiseCoverage *= noiseCoverage * 3.0;
	
	noise = fmix(noiseBase, noiseDetail, 0.025 * int(0 < noiseBase)) * 22.0 - noiseCoverage;
	noise = max(noise - END_DISK_AMOUNT - 1.0 + getProtoplanetaryDisk(rayPos), 0.0);
	noise /= sqrt(noise * noise + 0.25);
}

void computeEndVolumetricClouds(inout vec4 vc, in vec3 atmosphereColor, float z, float dither, inout float currentDepth) {
	//Total visibility
	float visibility = int(0.56 < z);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Positions
		vec3 viewPos = ToView(vec3(texCoord, z));
		vec3 nViewPos = normalize(viewPos);
        vec3 worldPos = ToWorld(viewPos);

		float VoU = dot(nViewPos, upVec);
		float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
		vec3 nWorldPos = normalize(worldPos);

        //float blackHoleDistortion = (pow8(VoS) * 0.5 + pow(VoS, 1.0 + VoS * 32.0) * 0.25) * min(length(nWorldPos.xz * 0.25), 64.0);
        float blackHoleDistortion = 0.0;
        nWorldPos.y += nWorldPos.x * END_ANGLE;
        nWorldPos.y -= blackHoleDistortion;
        #ifdef END_67
        if (frameCounter < 500) {
            nWorldPos.y += nWorldPos.x * 0.5 * sin(frameTimeCounter * 8);
        }
        #endif
		vec3 worldSunVec = ToWorld(normalize(sunVec * 10000.0));
			 worldSunVec.xz *= 32.0;

		#if MC_VERSION >= 12100 && defined END_FLASHES
		vec3 worldEndFlashPosition = ToWorld(normalize(endFlashPosition * 10000.0)) * 24.0;
		#endif

		#ifdef DISTANT_HORIZONS
		float dhZ = texture2D(dhDepthTex0, texCoord).r;
		vec4 dhScreenPos = vec4(texCoord, dhZ, 1.0);
		vec4 dhViewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
			 dhViewPos /= dhViewPos.w;
		#endif

		//Setting the ray marcher
		float cloudTop = END_DISK_HEIGHT + (END_DISK_THICKNESS + blackHoleDistortion * 5.0) * 10.0;
		float lowerPlane = (END_DISK_HEIGHT - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (cloudTop - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = max(lowerPlane, upperPlane);

		float planeDifference = maxDist - minDist;
		float rayLength = (END_DISK_THICKNESS + blackHoleDistortion * 5.0) * 8.0;
			  rayLength /= nWorldPos.y * nWorldPos.y * 8.0 + 1.0;
		vec3 startPos = cameraPosition + minDist * nWorldPos;
		vec3 sampleStep = nWorldPos * rayLength;
		int sampleCount = int(min(planeDifference / rayLength, 64) + dither);

		if (maxDist >= 0.0 && sampleCount > 0) {
			float cloud = 0.0;
			float cloudAlpha = 0.0;
			float cloudLighting = 0.0;

			//Scattering variables
			float halfVoLSqrt = VoS * 0.5 + 0.5;
			float halfVoL = halfVoLSqrt * halfVoLSqrt;
			float scattering = pow8(halfVoLSqrt);

			vec3 rayPos = startPos + sampleStep * dither;
			
			float maxDepth = currentDepth;
			float minimalNoise = 0.25 + dither * 0.25;
			float sampleTotalLength = minDist + rayLength * dither;

			vec2 wind = vec2(frameTimeCounter * 0.005, sin(frameTimeCounter * 0.1) * 0.01) * 0.1;

			//Ray marcher
			for (int i = 0; i < sampleCount; i++, rayPos += sampleStep, sampleTotalLength += rayLength) {
				if (0.99 < cloudAlpha || (length(viewPos) < sampleTotalLength && z < 1.0)) break;

				#ifdef DISTANT_HORIZONS
				if ((length(dhViewPos.xyz) < sampleTotalLength && dhZ < 1.0)) break;
				#endif

                vec3 worldPos = rayPos - cameraPosition;

				float shadow1 = clamp(shadow2D(shadowtex1, ToShadow(worldPos)).x, 0.0, 1.0);

				float noise = 0.0;
				float lightingNoise = 0.0;
				float rayDistance = length(worldPos.xz) * 0.1;
				float attenuation = smoothstep(END_DISK_HEIGHT, cloudTop, rayPos.y);

				getEndCloudSample(rayPos.xz, wind, attenuation, noise);

				#ifdef END_FLASHES
				getEndCloudSample(rayPos.xz + worldSunVec.xz + worldEndFlashPosition.xz * endFlashIntensity, wind, attenuation + worldSunVec.y * 0.15, lightingNoise);
				#else
				getEndCloudSample(rayPos.xz + worldSunVec.xz, wind, attenuation + worldSunVec.y * 0.15, lightingNoise);
				#endif

				float sampleLighting = 0.05 + clamp(noise - lightingNoise * (0.9 - scattering * 0.15), 0.0, 0.95) * (1.5 + scattering);
					  sampleLighting *= 1.0 - noise * 0.75;
					  sampleLighting = clamp(sampleLighting, 0.0, 1.0);

				cloudLighting = fmix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));
				if (rayDistance < shadowDistance * 0.1) noise *= shadow1;
				cloud = fmix(cloud, 1.0, noise);
				noise *= pow8(smoothstep(4000.0, 8.0, rayDistance)); //Fog
				cloudAlpha = fmix(cloudAlpha, 1.0, noise);

				//gbuffers_water cloud discard check
				if (noise > minimalNoise && currentDepth == maxDepth) {
					currentDepth = sampleTotalLength;
				}
			}

			//Final color calculations
            vec3 cloudColor = vec3(0.95, 1.0, 0.5) * endLightCol;
            #if MC_VERSION >= 12100 && defined END_FLASHES
            float endFlashPoint = endFlashPosToPoint(endFlashPosition, worldPos);
                 cloudColor = fmix(cloudColor, endFlashCol * (1.0 + endFlashPoint * endFlashPoint * 2.0), endFlashPoint * endFlashIntensity * 0.5);
            #endif
			     cloudColor *= cloudLighting * 0.35;

			vc = vec4(cloudColor, cloudAlpha * END_DISK_OPACITY) * visibility;
		}
	}
}
#endif