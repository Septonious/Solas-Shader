#ifndef BLOCKY_CLOUDS
const float stretching = VC_STRETCHING;
#else
const float stretching = 10.0;
#endif

#ifndef BLOCKY_CLOUDS
float getCloudSample(vec3 rayPos, float rayPosY) {
	rayPos *= 0.0025;

	vec3 floorPos = floor(rayPos);
	vec3 fractPos = fract(rayPos);

	vec2 noiseCoord = (floorPos.xz + fractPos.xz + floorPos.y * 16.0) * 0.5;

	float cloudLayer = abs(VC_HEIGHT - rayPosY) / stretching;
	float noise = 0.0;

	if (cloudLayer < 2.0) {
		noise = texture2D(noisetex, noiseCoord + frameTimeCounter * 0.00005).r;
		noise+= texture2D(noisetex, noiseCoord * 0.50000 + frameTimeCounter * 0.0001).r * 2.0;
		noise+= texture2D(noisetex, noiseCoord * 0.25000 + frameTimeCounter * 0.0002).r * 3.0;
		noise+= texture2D(noisetex, noiseCoord * 0.12500 + frameTimeCounter * 0.0003).r * 4.0;
		noise+= texture2D(noisetex, noiseCoord * 0.06250 + frameTimeCounter * 0.0004).r * 5.0;
		noise+= texture2D(noisetex, noiseCoord * 0.03125 + frameTimeCounter * 0.0005).r * 6.0;
		noise = clamp(noise - (10.0 + cloudLayer - rainStrength), 0.0, 1.0);
	}

	return noise;
}
#else
float getCloudSample(vec3 rayPos, float rayPosY) {
	rayPos = floor(rayPos * 0.5);
	rayPos *= 0.025;

	vec3 floorPos = floor(rayPos);
	vec3 fractPos = fract(rayPos);

	vec2 noiseCoord = (floorPos.xz + fractPos.xz + floorPos.y * 16.0) / 64.0;

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
		const float distanceFactor = 2000;
		
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
				  VoL = pow4(VoL);
			float lViewPos = length(viewPos) - 1.0;

			//Blend colors with the sky
			float atmosphereMixer = sunVisibility * 0.5;
			vec3 cloudLightCol = mix(lightCol, pow(atmosphereColor, vec3(1.5)), atmosphereMixer) * (1.0 + VoL * 2.0);
			vec3 cloudAmbientCol = mix(ambientCol, atmosphereColor * atmosphereColor, atmosphereMixer);

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
					  cloudLighting = mix(noise, cloudLighting * 0.9 + noise * 0.1, cloudLighting);
					  #endif

				float cloudFogFactor = clamp((distanceFactor - lWorldPos) / distanceFactor, 0.0, 1.0);

				vec4 cloudColor = vec4(mix(cloudLightCol, cloudAmbientCol, cloudLighting), noise * cloudFogFactor);
					 cloudColor.rgb *= cloudColor.a;

				vc += cloudColor * (1.0 - vc.a);
			}
		}
	}
	vc *= visibility;
	cloudDepth = vc.a;
}