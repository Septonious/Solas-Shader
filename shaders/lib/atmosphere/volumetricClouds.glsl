#ifndef BLOCKY_CLOUDS
const float stretching = VC_STRETCHING;
#else
const float stretching = 10.0;
#endif

float get3DNoise(vec2 noiseCoord, float wind, float fractPosY) {
	float planeA = texture2D(shadowcolor1, noiseCoord + wind).b;
	float planeB = texture2D(shadowcolor1, noiseCoord + wind + 0.25).b;
	
	return mix(planeA, planeB, fractPosY);
}

#ifndef BLOCKY_CLOUDS
float getCloudSample(vec3 rayPos, float rayPosY) {
	rayPos *= 0.0025;

	vec3 floorPos = floor(rayPos);
	vec3 fractPos = fract(rayPos);

	vec2 noiseCoord = (floorPos.xz + fractPos.xz + floorPos.y * 16.0) * 0.015625;

	float detailZ = floor(rayPos.y * 32.0 + 0.5) * 0.05;
	float noiseBase = get3DNoise(noiseCoord, frameTimeCounter * 0.0001, fractPos.y);
	float noiseDetail = get3DNoise(noiseCoord * 4.0, frameTimeCounter * 0.0002, fractPos.y);
	float noiseHighDetail = get3DNoise(noiseCoord * 16.0 + detailZ, frameTimeCounter * 0.0003, fractPos.y);

	float noise = (noiseBase + noiseDetail * 0.3 - noiseHighDetail * 0.2) * mix(16.0 * VC_AMOUNT, 20.0, rainStrength);

	float shapingNoise = clamp(noise - 10.0, 0.0, 1.0);
	float cloudShaping = clamp(smoothstep(VC_HEIGHT + stretching * shapingNoise, VC_HEIGHT - stretching * shapingNoise, rayPosY), 0.0, 1.0);

	return clamp(noise - mix(14.0, 10.0, sqrt(cloudShaping)), 0.0, 1.0);
}
#else
float getCloudSample(vec3 rayPos, float rayPosY) {
	rayPos = floor(rayPos * 0.5);
	rayPos *= 0.025;

	vec3 floorPos = floor(rayPos);
	vec3 fractPos = fract(rayPos);

	vec2 noiseCoord = (floorPos.xz + fractPos.xz + floorPos.y * 16.0) / 48.0;

	float planeA = texture2D(shadowcolor1, noiseCoord).r;
	float planeB = texture2D(shadowcolor1, noiseCoord + 0.25).r;
	
	float noise = mix(planeA, planeB, fractPos.y) * 100.0;

	return clamp(noise - 1.0, 0.0, 1.0);
}
#endif

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
		const float distanceFactor = 1300;
		
		//Set the two planes here between which the ray marching will be done
		float lowerPlane = (VC_HEIGHT + stretching - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (VC_HEIGHT - stretching - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = min(max(lowerPlane, upperPlane), distanceFactor);
		float rayLength = maxDist - minDist;

		#ifndef BLOCKY_CLOUDS
		int sampleCount = clamp(int(rayLength) / 4, 0, VC_SAMPLES);
		#else
		int sampleCount = clamp(int(rayLength), 0, VC_SAMPLES);
		#endif

		if (sampleCount > 0) {
			//Other variables
			vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
			float VoL = clamp(dot(normalize(viewPos), lightVec), 0.0, 1.0) * shadowFade;
			float lViewPos = length(viewPos) - 1.0;

			//Blend colors with the sky
			float atmosphereMixer = 0.5 * sunVisibility;
			vec3 cloudLightCol = mix(lightCol, pow(atmosphereColor, vec3(1.5)), atmosphereMixer) * (1.0 + (VoL + pow6(VoL)) * mefade * 0.5);
			vec3 cloudAmbientCol = mix(ambientCol, atmosphereColor * atmosphereColor, atmosphereMixer + 0.25);

			//Precompute the ray position
			vec3 rayPos = cameraPosition + nWorldPos * minDist;
			vec3 rayDir = nWorldPos * (rayLength / sampleCount);
			rayPos += rayDir * dither;
			rayPos.y -= rayDir.y;

			//Ray marching
			for (int i = 0; i < sampleCount; i++, rayPos += rayDir) {
				vec3 worldPos = rayPos - cameraPosition;

				float lWorldPos = length(worldPos);

				if (lViewPos < lWorldPos) break;

				//Indoor leak prevention
				if (eyeBrightnessSmooth.y <= 150.0) {
					if (shadow2D(shadowtex1, ToShadow(worldPos)).z == 0.0) break;
				}

				//Shaping
				float noise = getCloudSample(rayPos, rayPos.y);

				//Color calculations
				float cloudLighting = clamp(smoothstep(VC_HEIGHT + stretching * noise, VC_HEIGHT - stretching * noise, rayPos.y), 0.0, 1.0);
					  #ifndef BLOCKY_CLOUDS
					  cloudLighting = mix(noise * 0.85, cloudLighting * 0.75 + noise * 0.25, cloudLighting);
					  #endif

				float cloudFogFactor = pow(clamp((distanceFactor - lWorldPos) / distanceFactor, 0.0, 1.0), 1.0 + rainStrength);

				vec4 cloudColor = vec4(mix(cloudLightCol, cloudAmbientCol, cloudLighting), noise * cloudFogFactor);
					 cloudColor.rgb *= cloudColor.a;

				vc += cloudColor * (1.0 - vc.a);
			}
		}
	}
	vc *= visibility;
	cloudDepth = vc.a;
}