#ifndef BLOCKY_CLOUDS
const float stretching = VC_STRETCHING;
#else
const float stretching = 20.0;
#endif

float get3DNoise(vec2 noiseCoord, float wind, float fractPosY) {
	float planeA = texture2D(shadowcolor1, noiseCoord + wind).b;
	float planeB = texture2D(shadowcolor1, noiseCoord + wind + 0.25).b;
	
	return mix(planeA, planeB, fractPosY);
}

float getCloudSample(vec3 rayPos, float rayPosY, float cloudLayer) {
	rayPos *= 0.0025;

	vec3 floorPos = floor(rayPos);
	vec3 fractPos = fract(rayPos);

	vec2 noiseCoord = (floorPos.xz + fractPos.xz + floorPos.y * 16.0) * 0.015625;

	float detailZ = floor(rayPos.y * 32.0 + 0.5) * 0.05;
	float noiseBase = get3DNoise(noiseCoord, frameTimeCounter * 0.0002, fractPos.y);
	float noiseDetail = get3DNoise(noiseCoord * 4.0, frameTimeCounter * 0.0004, fractPos.y);
	float noiseHighDetail = get3DNoise(noiseCoord * 16.0 + detailZ, frameTimeCounter * 0.0006, fractPos.y);

	float noise = (noiseBase - noiseDetail * 0.2 - noiseHighDetail * 0.15) * 26.0 * VC_AMOUNT;

	float shapingNoise = clamp(noise - 10.0, 0.0, 1.0);
	float cloudShaping = clamp(smoothstep(VC_HEIGHT + stretching * shapingNoise, VC_HEIGHT - stretching * shapingNoise, rayPosY), 0.0, 1.0);

	return clamp(noise - mix(14.0, 10.0, sqrt(cloudShaping)), 0.0, 1.0);
}

void computeVolumetricClouds(inout vec4 vc, in vec3 atmosphereColor, in float z1, in float dither, inout float cloudDepth) {
	//Total visibility of clouds
	float visibility = caveFactor * int(z1 > 0.56);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Positions & Variables
		vec3 viewPos = ToView(vec3(texCoord, z1));
		vec3 nWorldPos = normalize(ToWorld(viewPos));
		vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

		float distanceFactor = min(far * 16.0, 1500.0);
		float VoL = clamp(dot(normalize(viewPos), lightVec), 0.0, 1.0) * shadowFade;

		//Blend colors with the sky
		lightCol *= 1.0 + pow8(VoL);
		ambientCol = mix(ambientCol, atmosphereColor, sunVisibility * 0.5);

		//Set the two planes here between which the ray marching will be done
		float lowerPlane = (VC_HEIGHT + stretching - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (VC_HEIGHT - stretching - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = min(max(lowerPlane, upperPlane), distanceFactor);
		float rayLength = maxDist - minDist;
		float lViewPos = length(viewPos);

		int sampleCount = clamp(int(rayLength), 0, VC_SAMPLES);

		//Precompute the ray position
		vec3 rayPos = cameraPosition + nWorldPos * minDist;
		vec3 rayDir = nWorldPos * (rayLength / sampleCount);
		rayPos += rayDir * dither;
		rayPos.y -= rayDir.y;

		//Ray marching
		for (int i = 0; i < sampleCount; i++, rayPos += rayDir) {
			vec3 worldPos = rayPos - cameraPosition;

			float lWorldPos = length(worldPos);
            float cloudLayer = abs(VC_HEIGHT - rayPos.y) / stretching;

			if (lWorldPos > distanceFactor || lViewPos - 1.0 < lWorldPos) break;

			//Indoor leak prevention
			if (eyeBrightnessSmooth.y <= 150.0) {
				vec3 shadowPos = calculateShadowPos(worldPos);
				float shadow1 = shadow2D(shadowtex1, shadowPos).z;

				if (shadow1 == 0.0) break;
			}

			//Shaping and lighting
            float noise = getCloudSample(rayPos, rayPos.y, cloudLayer);

			//Color calculations
			float cloudLighting = clamp(smoothstep(VC_HEIGHT + stretching * noise, VC_HEIGHT - stretching * noise, rayPos.y), 0.0, 1.0);
				  cloudLighting = pow(cloudLighting, 5.0 + VoL);
				  cloudLighting = mix(noise * 0.85, mix(cloudLighting * 0.8 + noise * 0.2, cloudLighting * 0.6 + noise * 0.4, VoL), cloudLighting);

			float cloudFog = clamp((distanceFactor - lWorldPos) / distanceFactor * 2.0, 0.0, 1.0);

			vec4 cloudColor = vec4(mix(lightCol, ambientCol, cloudLighting), noise * cloudFog);
				 cloudColor.rgb *= cloudColor.a;

			vc += cloudColor * (1.0 - vc.a);
		}
	}
	vc *= visibility;
	cloudDepth = vc.a;
}