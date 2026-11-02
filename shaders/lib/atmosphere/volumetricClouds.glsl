float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

#ifdef VOLUMETRIC_CLOUDS
void getDynamicWeather(inout float speed, inout float amount, inout float thickness, inout float density, inout float detail, inout float height, inout float scale) {
	#ifdef VC_DYNAMIC_WEATHER
	float day = float(worldDay) + timeAngle;
    float sinDay05 = sin(day * 0.5);
    float cosDay075 = cos(day * 0.75);
    float cosDay15 = cos(day * 1.5);
    float sinDay2 = sin(day * 2.0);
    float waveFunction = sinDay05 * cosDay075 + sinDay2 * 0.25 - cosDay15 * 0.75;

    amount += waveFunction * (0.5 + cosDay075 * 0.5) * 0.5 + moonVisibility * 0.125;
    height += waveFunction * sinDay2 * 75.0;
    scale += waveFunction * cosDay075 - moonVisibility * 0.25;
    thickness += waveFunction * waveFunction * cosDay15;
    density += waveFunction * sinDay05;
	#endif

	#if MC_VERSION >= 12104
    amount -= isPaleGarden;
	#endif
}

float CloudLocalTop(float noiseBase) {
	float localTop = clamp((noiseBase - 0.48) * 2.15, 0.0, 1.0);
	      localTop = localTop * localTop * (3.0 - 2.0 * localTop);

	return mix(0.70, 1.08, localTop);
}

float CloudVerticalCoverage(float sampleAltitude, float noiseBase) {
	float localTop = CloudLocalTop(noiseBase);

	float bottomPenalty = (1.0 - smoothstep(0.00, 0.18, sampleAltitude)) * 0.35;
	float topPenalty = smoothstep(localTop - 0.20, localTop + 0.12, sampleAltitude) * 0.85;
	float planeGuard = smoothstep(0.94, 1.0, sampleAltitude) * 0.90;

	return bottomPenalty + max(topPenalty, planeGuard);
}

float CloudHeightDensity(float sampleAltitude, float noiseBase) {
	float localTop = CloudLocalTop(noiseBase);

	float bottomFade = smoothstep(0.00, 0.18, sampleAltitude);
	float bodyFade = 0.82 + smoothstep(0.16, 0.58, sampleAltitude) * 0.18;
	float topFade = 1.0 - smoothstep(localTop - 0.20, localTop + 0.14, sampleAltitude) * 0.45;
	float planeFade = 1.0 - smoothstep(0.965, 1.0, sampleAltitude);

	return clamp((0.30 + bottomFade * 0.70) * bodyFade * topFade * planeFade, 0.0, 1.08);
}

float cloudSampleBase(vec2 coord) {
	float perlinBase = texture2D(noisetex, coord * 0.5 + vec2(0.17, -0.11)).r * 0.6;
	      perlinBase += texture2D(noisetex, coord * 1.5 + vec2(-0.07, 0.19)).r * 0.4;
		  perlinBase = perlinBase * 0.9 + pow3(perlinBase) * 0.4;

	return clamp((perlinBase - 0.35) * 1.4 + 0.5, 0.0, 1.0);
}

float CloudSampleDetail(vec2 coord, float sampleAltitude, float thickness) {
	float detailZ = floor(sampleAltitude * float(thickness)) * 0.04;
	float detailFrac = fract(sampleAltitude * float(thickness));

	float noiseDetailLow = texture2D(noisetex, coord.xy + detailZ).g;
	float noiseDetailHigh = texture2D(noisetex, coord.xy + detailZ + 0.04).g;

	float noiseDetail = fmix(noiseDetailLow, noiseDetailHigh, detailFrac);

	return noiseDetail;
}

float CloudCoverageDefault(float sampleAltitude, float amount) {
	float noiseCoverage = abs(sampleAltitude - 0.125);

	noiseCoverage *= sampleAltitude > 0.125 ? (2.5 - amount * 0.1) : 8.0;
	noiseCoverage = noiseCoverage * noiseCoverage * 4.0;

	return noiseCoverage;
}

float CloudApplyDensity(float noise, float density) {
	noise *= density * 0.125;
	noise *= (1.0 - 0.25 * wetness);
	noise = noise / sqrt(noise * noise + 0.5);

	return noise;
}

float CloudCombineDefault(float noiseBase, float noiseDetail, float noiseCoverage, float amount, float density) {
	float noise = fmix(noiseBase, noiseDetail, 0.0476 * VC_DETAIL) * 21.0;

	noise = fmix(noise - noiseCoverage, 21.0 - noiseCoverage * 2.5, 0.2 * wetness);
	noise = max(noise - amount, 0.0);

	noise = CloudApplyDensity(noise, density);

	return noise;
}

float CloudSample(vec2 coord, vec2 wind, float sampleAltitude, float thickness, float amount, float density) {
	coord *= 0.0025;

	vec2 baseCoord = coord * 0.5 + wind * 2.0;
	vec2 detailCoord = coord.xy * 10.0 - wind * 2.0;

	float noiseBase = cloudSampleBase(baseCoord);
	float noiseDetail = CloudSampleDetail(detailCoord, sampleAltitude, thickness);
	float noiseCoverage = CloudCoverageDefault(sampleAltitude, amount);
	      noiseCoverage += CloudVerticalCoverage(sampleAltitude, noiseBase);

	float noise = CloudCombineDefault(noiseBase, noiseDetail, noiseCoverage, amount, density);
	      noise *= CloudHeightDensity(sampleAltitude, noiseBase);

	return noise;
}

float CloudSampleLowDetail(vec2 coord, vec2 wind, float sampleAltitude, float thickness, float amount, float density) {
	coord *= 0.0025;

	vec2 baseCoord = coord * 0.5 + wind * 2.0;

	float noiseBase = cloudSampleBase(baseCoord);
	float noiseCoverage = CloudCoverageDefault(sampleAltitude, amount);
	      noiseCoverage += CloudVerticalCoverage(sampleAltitude, noiseBase);

	float noise = CloudCombineDefault(noiseBase, 0.0, noiseCoverage, amount, density);
	      noise *= CloudHeightDensity(sampleAltitude, noiseBase);

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
		vec3 worldPos0 = ToWorld(viewPos);
		vec3 nWorldPos = normalize(worldPos0);
        float lViewPos = length(viewPos);

		#if defined DISTANT_HORIZONS
		float dhZ = texture2D(dhDepthTex0, texCoord).r;
		vec4 dhScreenPos = vec4(texCoord, dhZ, 1.0);
		vec4 dhViewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
			    dhViewPos /= dhViewPos.w;
		float lDhViewPos = length(dhViewPos.xyz);
		#elif defined VOXY
		float vxZ = texture2D(vxDepthTexOpaque, texCoord).r;
		vec4 vxScreenPos = vec4(texCoord, vxZ, 1.0);
		vec4 vxViewPos = vxProjInv * (vxScreenPos * 2.0 - 1.0);
		        vxViewPos /= vxViewPos.w;
		float lVxViewPos = length(vxViewPos.xyz);
		#endif

		//Cloud parameters
		float speed = VC_SPEED;
		float amount = VC_AMOUNT;
		float thickness = VC_THICKNESS;
		float density = VC_DENSITY;
		float detail = VC_DETAIL;
		float height = VC_HEIGHT;
        float scale = VC_SCALE;
        float distance = VC_DISTANCE;

		getDynamicWeather(speed, amount, thickness, density, detail, height, scale);

        //Aurora influence
        #ifdef AURORA_LIGHTING_INFLUENCE
        //The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
        float kpIndex = abs(worldDay % 9 - worldDay % 4);
              kpIndex = kpIndex - int(kpIndex == 1) + int(kpIndex > 7 && worldDay % 10 == 0);
              kpIndex = min(max(kpIndex, 0) + isSnowy * 4, 9);
        #ifdef AURORA_ALWAYS_VISIBLE
              kpIndex = 7;
        #endif

        //Total visibility of aurora based on multiple factors
        float auroraVisibility = pow6(moonVisibility) * (1.0 - wetness) * caveFactor;

        //Aurora tends to get brighter and dimmer when plasma arrives or fades away
        float pulse = 0.5 + 0.5 * sin(frameTimeCounter * 0.08 + sin(frameTimeCounter * 0.013) * 0.6);
              pulse = smoothstep(0.15, 0.85, pulse);

        float longPulse = sin(frameTimeCounter * 0.025 + sin(frameTimeCounter * 0.004) * 0.8);
              longPulse = longPulse * (1.0 - 0.15 * abs(longPulse));

        kpIndex *= 1.0 + longPulse * 0.25;
        kpIndex /= 9.0;

		//When aurora turns red
		float redPhase = pow3(kpIndex) * (1.0 - pulse);

        //Aurora distribution parameters
        float westEast = clamp(1.0 - abs(nWorldPos.x * 0.05) + kpIndex * kpIndex, 0.0, 1.0); //Fade out aurora closer to the western/eastern horizons
        float north = clamp(10.0 * kpIndex * kpIndex * kpIndex - nWorldPos.z, 0.0, 1.0); //Make aurora appear stronger in north when looking from the ground
        float auroraDistanceFactor = clamp(1.0 - length(nWorldPos.xz) * 0.02, 0.0, 1.0); //Limit the max render distance

        auroraVisibility *= kpIndex * (1.0 + max(longPulse * 0.5, 0.0));
        auroraVisibility = min(auroraVisibility, 2.0) * AURORA_BRIGHTNESS * 10;
        auroraVisibility *= auroraDistanceFactor * auroraDistanceFactor * north * westEast;

        float colorMixer = 0.65 + pow3(kpIndex) * pulse * 0.1;
        vec3 lowColor = vec3(0.45, 1.55 - redPhase * 0.5, 0.0);
        vec3 upColor = vec3(0.95 + redPhase * 5.0, 0.10, 0.0);
        vec3 auroraColor = fmix(lowColor, upColor, colorMixer);
        #endif

		//Ray marcher peramters
        int maxsampleCount = 24;

        float cloudBottom = height;
        float cloudSpan = thickness * scale * 1.18;
        float cloudTop = cloudBottom + cloudSpan;

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
            int sampleCount = int(min(planeDifference / rayLength, maxsampleCount) + 4);

            vec3 startPos = cameraPosition + nearestPlane * nWorldPos;
            vec3 rayPos = startPos + rayIncrement * dither;
            float sampleTotalLength = nearestPlane + rayLength * dither;

            float time = (timeAngle + float(worldDay % 100 + 5)) * 1200.0;
            vec2 wind = vec2(time * speed * 0.005, sin(time * speed * 0.1) * 0.01) * speed * 0.05;

            float cloud = 0.0;
            float cloudFaded = 0.0;
            float cloudLighting = 0.0;
			float ambientLighting = 0.0;

            float VoL = dot(nViewPos, lightVec);

            float halfVoL = fmix(abs(VoL) * 0.8, VoL, shadowFade) * 0.5 + 0.5;
            float halfVoLSqr = halfVoL * halfVoL;
            float scattering = pow8(halfVoL);

            float distanceFade = 1.0;
            float fadeStart = 32.0 / max(FOG_DENSITY, 0.5);
            float fadeEnd = distance / max(FOG_DENSITY, 0.5);

            float xzNormalizeFactor = 10.0 / max(abs(height - 72.0), 56.0);

			vec3 worldLightVec = normalize(ToWorld(lightVec * 100000000.0));
                 worldLightVec *= (4.0 - scattering * scattering * 2.0) * shadowFade;

            for (int i = 0; i < sampleCount; i++, rayPos += rayIncrement, sampleTotalLength += rayLength) {
                if (cloud > 0.99 || (lViewPos < sampleTotalLength && z < 1.0) || sampleTotalLength > distance * 32.0) break;

				#if defined DISTANT_HORIZONS
				if ((lDhViewPos < sampleTotalLength && dhZ < 1.0)) break;
				#elif defined VOXY
				if ((lVxViewPos < sampleTotalLength && vxZ < 1.0)) break;
				#endif

                vec3 worldPos = rayPos - cameraPosition;
				float lWorldPos = length(worldPos.xz);

				//Indoor leak prevention
				if (eyeBrightnessSmooth.y < 210.0 && cameraPosition.y > height - 50.0 && lWorldPos < shadowDistance) {
					if (texture2DShadow(shadowtex1, ToShadow(worldPos)) <= 0.0) break;
				}

                float xzNormalizedDistance = length(rayPos.xz - cameraPosition.xz) * xzNormalizeFactor;
                vec2 cloudCoord = rayPos.xz / scale;

				float sampleAltitude = InvLerp(rayPos.y, cloudBottom, cloudTop);
                float attenuation = step(cloudBottom, rayPos.y) * step(rayPos.y, cloudTop);

                float noise = CloudSample(cloudCoord, wind, sampleAltitude, thickness, amount, density);
                      noise *= attenuation * step(xzNormalizedDistance, fadeEnd);

                if (noise <= 0.0001) continue;

				float sampleAltitudeL = InvLerp(rayPos.y + worldLightVec.y, cloudBottom, cloudTop);
                float attenuationL = step(cloudBottom, rayPos.y + worldLightVec.y) * step(rayPos.y + worldLightVec.y, cloudTop);

                float lightingNoise = CloudSampleLowDetail(cloudCoord + worldLightVec.xy, wind, sampleAltitudeL, thickness, amount, density);
                      lightingNoise *= attenuationL;

				float powder = 1.0 - exp(-pow4(noise) * 0.75);
				float lightTransmittance = exp(-lightingNoise * (4.0 - timeBrightness)) * (1.0 + scattering * scattering);
				float sampleLighting1 = clamp(powder * lightTransmittance, 0.0, 1.0);
                float sampleLighting2 = clamp(sampleAltitude * (2.0 + lightTransmittance * 2.0 - scattering * scattering), 0.0, 1.0);

                cloudLighting = fmix(cloudLighting, sampleLighting1, noise * (1.0 - cloud * cloud));
				ambientLighting = fmix(ambientLighting, sampleLighting2, noise * (1.0 - cloud * cloud));

                float sampleFade = InvLerp(xzNormalizedDistance, fadeEnd, fadeStart);
                distanceFade *= fmix(1.0, sampleFade, noise * (1.0 - cloud));

                cloud = fmix(cloud, 1.0, noise);

                cloudFaded = fmix(cloudFaded, 1.0, noise);

                if (currentDepth == maxDist && cloud > 0.5) {
                    currentDepth = sampleTotalLength;
                }
            }

            cloudFaded *= distanceFade;
			if (cloudFaded < dither) {
				currentDepth = maxDist;
			}

            //Final color calculations
			vec3 nSkyColor = normalize(skyColor + 0.0001);
            vec3 atmColor22 = pow(atmosphereColor, vec3(2.2));
            vec3 cloudAmbientColor = fmix(atmColor22, atmColor22 * mix(vec3(1.0), nSkyColor * 0.5, isSpecificBiome), timeBrightnessSqrt) * (0.75 + scattering * 0.25 - wetness * 0.5);

            vec3 cloudLightColor = fmix(lightCol, lightCol * nSkyColor * 2.0, timeBrightnessSqrt);
                 cloudLightColor *= 0.125 + cloudLighting * ((0.475 + 0.4 * shadowFade + moonVisibility * 0.4) + scattering * 1.825);
				 cloudLightColor = fmix(cloudAmbientColor, cloudLightColor, fmix(0.5 + cloudLighting, 1.0, scattering));
                //Aurora influence
                #ifdef AURORA_LIGHTING_INFLUENCE
                 cloudLightColor *= 1.0 + auroraColor * auroraVisibility * 2.0;
                 cloudLightColor /= 1.0 + auroraVisibility;
                #endif
			vec3 cloudColor = fmix(cloudAmbientColor, cloudLightColor, ambientLighting) * fmix(vec3(1.0), biomeColor, isSpecificBiome * sunVisibility);

            float opacity = clamp(fmix(VC_OPACITY * (1.0 - wetness * 0.25), 1.0, (max(0.0, cameraPosition.y - thickness * 10.0) / height)), 0.0, 1.0);

            #if MC_VERSION >= 12104
            opacity = fmix(opacity, opacity * 0.5, isPaleGarden);
            #endif

            cloudFaded = pow(max(cloudFaded, 0.0), 1.82) * opacity;
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
    vec2 nWorldPos = worldPos.xz / (length(worldPos) + worldPos.y) - flashCoord;
    float flashPoint = 1.0 - clamp(length(nWorldPos), 0.0, 1.0);

    return flashPoint;
}
#endif

float getProtoplanetaryDisk(vec2 coord){
	float whirl = -5;
	float arms = 5;

    coord = vec2(atan(coord.y, coord.x) + frameTimeCounter * 0.01, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow4(1.0 - coord.y) * 1.0;
    float spiral = sin((coord.x + sqrt(coord.y) * whirl) * arms) + center - coord.y;

    return spiral;
}

void getEndCloudSample(vec2 rayPos, vec2 wind, float attenuation, inout float noise) {
	rayPos *= 0.00025;

	float worleyNoise = (1.0 - texture2D(noisetex, rayPos.xy + wind * 0.5).g) * 0.5 + 0.25;
	float perlinNoise = texture2D(noisetex, rayPos.xy + wind * 0.5).r;
	float noiseBase = perlinNoise * 0.5 + worleyNoise * 0.5;

	float detailZ = floor(attenuation * END_DISK_THICKNESS) * 0.05;
	float noiseDetailA = texture2D(noisetex, rayPos  - wind + detailZ).b;
	float noiseDetailB = texture2D(noisetex, rayPos  - wind + detailZ + 0.05).b;
	float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * END_DISK_THICKNESS));

	float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.14 : 7.0);
		     noiseCoverage *= noiseCoverage * 7.0;

	noise = mix(noiseBase, noiseDetail, 0.025 * int(0 < noiseBase)) * 22.0 - noiseCoverage;
	noise = max(noise - END_DISK_AMOUNT - 1.0 + getProtoplanetaryDisk(rayPos) * 2.0, 0.0);
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

        //float blackHoleDistortion = (pow8(VoS) * 0.5 + pow(VoS, 1.0 + VoS * 32.0) * 0.25) * min(length(nWorldPos.xz * 0.25), 64.0) * 0.75;
        float blackHoleDistortion = 0.0;
		#ifdef END_TIME_TILT
			float time = min(0.025 * frameTimeCounter, 1.0);
			nWorldPos.y += nWorldPos.x * time;
			blackHoleDistortion *= time;
		#endif
        nWorldPos.y += nWorldPos.x * END_ANGLE;
        nWorldPos.y -= blackHoleDistortion;
        #ifdef END_67
        if (frameCounter < 500) {
            nWorldPos.y += nWorldPos.x * 0.5 * sin(frameTimeCounter * 8);
        }
        #endif

		#if MC_VERSION >= 12100 && defined END_FLASHES
		vec3 worldEndFlashPosition = ToWorld(normalize(endFlashPosition * 10000.0)) * 24.0;
		#endif

		#if defined DISTANT_HORIZONS
		float dhZ = texture2D(dhDepthTex0, texCoord).r;
		vec4 dhScreenPos = vec4(texCoord, dhZ, 1.0);
		vec4 dhViewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
			 dhViewPos /= dhViewPos.w;
		float lDhViewPos = length(dhViewPos.xyz);
		#elif defined VOXY
		float vxZ = texture2D(vxDepthTexOpaque, texCoord).r;
		vec4 vxScreenPos = vec4(texCoord, vxZ, 1.0);
		vec4 vxViewPos = vxProjInv * (vxScreenPos * 2.0 - 1.0);
		     vxViewPos /= vxViewPos.w;
		float lVxViewPos = length(vxViewPos.xyz);
		#endif

		//Setting the ray marcher
		float cloudTop = END_DISK_HEIGHT + (END_DISK_THICKNESS + blackHoleDistortion * 5.0) * 10.0;
		float lowerPlane = (END_DISK_HEIGHT - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (cloudTop - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = max(lowerPlane, upperPlane);

		float planeDifference = maxDist - minDist;
		float rayLength = (END_DISK_THICKNESS + blackHoleDistortion * 5.0) * 6.0;
			    rayLength /= nWorldPos.y * nWorldPos.y * 6.0 + 1.0;
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

            vec3 worldLightVec = normalize(ToWorld(sunVec * 100000000.0));
                    worldLightVec.xz *= 32.0;

			vec3 rayPos = startPos + sampleStep * dither;

			float maxDepth = currentDepth;
			float minimalNoise = 0.25 + dither * 0.25;
			float sampleTotalLength = minDist + rayLength * dither;

			vec2 wind = vec2(frameTimeCounter * 0.005, sin(frameTimeCounter * 0.1) * 0.01) * 0.1;

			//Ray marcher
			for (int i = 0; i < sampleCount; i++, rayPos += sampleStep, sampleTotalLength += rayLength) {
				if (0.99 < cloudAlpha || (length(viewPos) < sampleTotalLength && z < 1.0)) break;

				#if defined DISTANT_HORIZONS
				if ((lDhViewPos < sampleTotalLength && dhZ < 1.0)) break;
				#elif defined VOXY
				if ((lVxViewPos < sampleTotalLength && vxZ < 1.0)) break;
				#endif

                vec3 worldPos = rayPos - cameraPosition;

				float shadow1 = clamp(texture2DShadow(shadowtex1, ToShadow(worldPos)), 0.0, 1.0);

				float noise = 0.0;
				float lightingNoise = 0.0;
				float rayDistance = length(worldPos.xz) * 0.1;
				float attenuation = smoothstep(END_DISK_HEIGHT, cloudTop, rayPos.y);

                getEndCloudSample(rayPos.xz, wind, attenuation, noise);
                getEndCloudSample(rayPos.xz + worldLightVec.xz, wind, attenuation , lightingNoise);

				float powder = 1.0 - 0.925 * exp(-pow(noise, 1.0 + noise * 7.0));
				float directionalScattering = 1.0 - exp(-2.0 * (noise - lightingNoise * 0.9));
                float sampleLighting = clamp((0.125 + attenuation * 0.875) * powder * directionalScattering * 2.0, 0.0, 1.0);

                cloudLighting = fmix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));

				if (length(worldPos) < shadowDistance) cloudLighting *= 0.5 + shadow1 * 0.5;
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
			     cloudColor *= cloudLighting * (1.0 + scattering);

			vc = vec4(cloudColor, cloudAlpha * END_DISK_OPACITY) * visibility;
		}
	}
}
#endif
