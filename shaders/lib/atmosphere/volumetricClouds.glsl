#ifndef BLOCKY_CLOUDS
const float stretching = VC_STRETCHING;

float get3DNoise(vec3 pos) {
	pos *= 0.4;
	pos.xz *= 0.4;

	vec3 floorPos = floor(pos);
	vec3 fractPos = fract(pos);

	vec2 noiseCoord = (floorPos.xz + fractPos.xz + floorPos.y * 16.0) * 0.015625;

	float planeA = texture2D(shadowcolor1, noiseCoord).r;
	float planeB = texture2D(shadowcolor1, noiseCoord + 0.25).r;

	return mix(planeA, planeB, fractPos.y);
}
#else
const float stretching = 12.0;

float get3DNoise(vec3 pos) {
	pos *= 0.5;
	pos.xz *= 0.5;

	vec3 floorPos = floor(pos);
	vec3 fractPos = fract(pos);

	vec2 noiseCoord = (floorPos.xz + fractPos.xz + floorPos.y * 16.0) * 0.015625;

	float planeA = texture2D(shadowcolor1, noiseCoord).a;
	float planeB = texture2D(shadowcolor1, noiseCoord + 0.25).a;

	return mix(planeA, planeB, fractPos.y);
}
#endif

float getCloudNoise(vec3 rayPos, float cloudLayer) {
	#ifndef BLOCKY_CLOUDS
	float noise = get3DNoise(rayPos * 0.5000 + frameTimeCounter * 0.4) * 1.25;
		  noise+= get3DNoise(rayPos * 0.2500 + frameTimeCounter * 0.3) * 1.75;
		  noise+= get3DNoise(rayPos * 0.1250 + frameTimeCounter * 0.2) * 3.50;
		  noise+= get3DNoise(rayPos * 0.0625 + frameTimeCounter * 0.1) * 6.75;
	#else
	float noise = get3DNoise(floor(rayPos) * 0.035) * 1000.0;
	#endif

	return clamp(noise * (VC_AMOUNT * (1.0 + rainStrength * 0.1)) - (4.0 + cloudLayer), 0.0, 1.0);
}

void computeVolumetricClouds(inout vec4 vc, in vec3 atmosphereColor, in float dither, in float caveFactor, inout float cloudDepth) {
	//Variables
	float z0 = texture2D(depthtex0, texCoord).r;
	float visibility = caveFactor * float(z0 > 0.56);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Positions & Variables
		vec4 screenPos = vec4(texCoord, z0, 1.0);
		vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		viewPos /= viewPos.w;

		vec3 nWorldPos = normalize(mat3(gbufferModelViewInverse) * viewPos.xyz);
		vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

		float VoL = clamp(dot(normalize(viewPos.xyz), lightVec) * shadowFade, 0.0, 1.0);
		float lViewPos = length(viewPos);

		ambientCol = mix(ambientCol, atmosphereColor, sunVisibility * (0.2 + timeBrightness * 0.8) * (1.0 - rainStrength * 0.5)) * (1.0 - timeBrightness * 0.6);
		lightCol = mix(lightCol, atmosphereColor, sunVisibility * 0.5);
		
		lightCol *= 1.0 + pow16(VoL) * 2.0;

		//We want to march between two planes which we set here
		float lowerPlane = (VC_HEIGHT + stretching - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (VC_HEIGHT - stretching - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = min(max(lowerPlane, upperPlane), VC_DISTANCE);
		float rayLength = maxDist - minDist;

		int sampleCount = clamp(int(rayLength), 1, VC_SAMPLES);

		//Precompute the ray position
		vec3 rayPos = cameraPosition + nWorldPos * minDist;
		vec3 rayDir = nWorldPos * (rayLength / sampleCount);
		rayPos += rayDir * dither;
		rayPos.y -= rayDir.y;

		//Ray marching and main calculations
		for (int i = 0; i < sampleCount; i++, rayPos += rayDir) {
			vec3 worldPos = rayPos - cameraPosition;

			float lWorldPos = length(worldPos);
			float cloudLayer = abs(VC_HEIGHT - rayPos.y) / stretching;
            float cloudVisibility = float(cloudLayer < 2.0);

			if (cloudVisibility == 0.0 || lWorldPos > VC_DISTANCE || lViewPos - 1.0 < lWorldPos) break;

			//Indoor leak prevention
			if (eyeBrightnessSmooth.y <= 150.0) {
				vec3 shadowPos = calculateShadowPos(worldPos);
				float shadow1 = shadow2D(shadowtex1, shadowPos).z;

				cloudVisibility *= 1.0 - float(shadow1 != 1.0);
			}

			//Shaping & Lighting
			if (cloudVisibility > 0.0) {
				//Cloud Noise
                float noise = getCloudNoise(rayPos, cloudLayer);

				//Color Calculations
				float cloudLighting = clamp(smoothstep(VC_HEIGHT + stretching * noise, VC_HEIGHT - stretching * noise, rayPos.y) * 0.75 + noise * 0.6, 0.0, 1.0);

				#ifdef VC_DISTANT_FADE
				float cloudDistantFade = clamp((VC_DISTANCE - lWorldPos) / VC_DISTANCE * 2.0, 0.0, 1.0);
				#endif

				vec4 cloudColor = vec4(mix(lightCol, ambientCol, cloudLighting), noise);
					 #ifdef VC_DISTANT_FADE
					 cloudColor.a = mix(0.0, cloudColor.a, cloudDistantFade);
					 #endif
					 cloudColor.rgb *= cloudColor.a;

				vc += cloudColor * (1.0 - vc.a);
			}
		}

		vc *= caveFactor;
		cloudDepth = vc.a;
	}
}