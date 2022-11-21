#ifndef BLOCKY_CLOUDS
const float stretching = VC_STRETCHING;
#else
const float stretching = 20.0;
#endif

float texture3DNoise(vec3 rayPos) {
	rayPos *= 0.025;

	vec3 floorPos = floor(rayPos);
	vec3 fractPos = fract(rayPos);

	vec2 noiseCoord = (floorPos.xz + fractPos.xz + floorPos.y * 16.0) * 0.015625;

	#ifndef BLOCKY_CLOUDS
	return texture2D(shadowcolor1, noiseCoord + 0.25).x;
	#else
	return texture2D(shadowcolor1, noiseCoord + 0.25).a;
	#endif
}

float getCloudNoise(vec3 rayPos, float cloudLayer) {
	#ifndef BLOCKY_CLOUDS
	float noise = texture3DNoise(rayPos * 0.25 - frameTimeCounter * 0.01) * 6.5;
		  noise+= texture3DNoise(rayPos * 0.50 - frameTimeCounter * 0.02) * 4.0;
		  noise+= texture3DNoise(rayPos * 1.00 - frameTimeCounter * 0.03) * 2.5;
		  noise+= texture3DNoise(rayPos * 2.00 - frameTimeCounter * 0.04) * 1.5;
	#else
	float noise = texture3DNoise(floor(rayPos * 0.25)) * 100.0;
	#endif

	return clamp(noise - VC_AMOUNT - 6.0 - cloudLayer * 1.5 + rainStrength, 0.0, 1.0);
}

void computeVolumetricClouds(inout vec4 vc, in vec3 atmosphereColor, in float z1, in float dither, inout float cloudDepth) {
	//Total visibility of clouds
	float visibility = caveFactor * float(z1 > 0.56);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Positions & Variables
		vec3 viewPos = ToView(vec3(texCoord, z1));
		vec3 nWorldPos = normalize(ToWorld(viewPos));

		vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
		float VoL = clamp(dot(normalize(viewPos), lightVec) * shadowFade, 0.0, 1.0);
		float lViewPos = length(viewPos);

		//Blend ambient and light colors with the sky
		ambientCol = mix(ambientCol, atmosphereColor, sunVisibility * 0.25 * (1.0 - rainStrength * 0.5));
		lightCol = mix(lightCol, atmosphereColor, sunVisibility * 0.5) * (1.0 + pow14(VoL));

		//Set the two planes here between which the ray marching will be done
		float lowerPlane = (VC_HEIGHT + stretching - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (VC_HEIGHT - stretching - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = min(max(lowerPlane, upperPlane), VC_DISTANCE);
		float rayLength = maxDist - minDist;

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
            float cloudVisibility = float(cloudLayer < 2.0);

			if (cloudVisibility == 0.0 || lWorldPos > VC_DISTANCE || lViewPos - 1.0 < lWorldPos) break;

			//Indoor leak prevention
			if (eyeBrightnessSmooth.y <= 150.0) {
				vec3 shadowPos = calculateShadowPos(worldPos);
				float shadow1 = shadow2D(shadowtex1, shadowPos).z;

				cloudVisibility *= 1.0 - float(shadow1 != 1.0);
			}

			//Shaping and lighting
			if (cloudVisibility > 0.0) {
                float noise = getCloudNoise(rayPos, cloudLayer);

				//Color calculations
				#ifndef BLOCKY_CLOUDS
				float cloudLighting = clamp(smoothstep(VC_HEIGHT + stretching * noise, VC_HEIGHT - stretching * noise, rayPos.y) * 0.75 + noise * 0.5, 0.0, 1.0);
				#else
				float cloudLighting = clamp(smoothstep(VC_HEIGHT + stretching * noise, VC_HEIGHT - stretching * noise, rayPos.y), 0.0, 1.0);
				#endif

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
		vc *= visibility;
		cloudDepth = vc.a;
	}
}