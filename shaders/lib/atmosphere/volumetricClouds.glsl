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
	float noise = get3DNoise(rayPos * 0.500000 - frameTimeCounter * 0.5);
		  noise+= get3DNoise(rayPos * 0.250000 - frameTimeCounter * 0.4) * 2.00;
		  noise+= get3DNoise(rayPos * 0.125000 - frameTimeCounter * 0.3) * 3.00;
		  noise+= get3DNoise(rayPos * 0.062500 - frameTimeCounter * 0.2) * 4.00;
		  noise+= get3DNoise(rayPos * 0.031250 - frameTimeCounter * 0.1) * 5.00;
		  noise+= get3DNoise(rayPos * 0.016125) * 6.00;

		  noise *= mix(VC_AMOUNT, 0.80, rainStrength);
	#else
	float noise = get3DNoise(floor(rayPos) * 0.035) * 1000.0;
	#endif

	return clamp(noise - (7.25 + cloudLayer), 0.0, 1.0);
}

void computeVolumetricClouds(inout vec3 color, in vec3 atmosphereColor, in float dither, inout float cloudDepth) {
	vec4 vc = vec4(0.0);

	//Total visibility of clouds
	float z0 = texture2D(depthtex0, texCoord).r;
	float visibility = caveFactor * float(z0 > 0.56);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Positions & Variables
		vec3 viewPos = ToView(vec3(texCoord, z0));
		vec3 nWorldPos = normalize(ToWorld(viewPos));

		vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
		float VoL = clamp(dot(normalize(viewPos), lightVec) * shadowFade, 0.0, 1.0);
		float lViewPos = length(viewPos);

		//Blend ambient and light colors with the sky
		ambientCol = mix(ambientCol, atmosphereColor, sunVisibility * (0.1 + timeBrightness * 0.2) * (1.0 - rainStrength * 0.5));
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
            float cloudVisibility = float(cloudLayer < 4.0);

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
				float cloudLighting = clamp(smoothstep(VC_HEIGHT + stretching * noise, VC_HEIGHT - stretching * noise, rayPos.y) * 0.7 + noise * 0.6, 0.0, 1.0);

				#ifdef VC_DISTANT_FADE
				float cloudDistantFade = clamp((VC_DISTANCE - lWorldPos) / VC_DISTANCE * 2.0, 0.0, 0.75);
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

	color = mix(color, pow(vc.rgb, vec3(1.0 / 2.2)), vc.a * vc.a * mix(VC_OPACITY, 0.4, rainStrength));
}