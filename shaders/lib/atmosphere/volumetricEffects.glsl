#ifdef VC
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
	fractPos = fractPos * fractPos * (3.0 - 2.0 * fractPos);

	vec2 noiseCoord = (floorPos.xz + fractPos.xz + floorPos.y * 16.0) * 0.015625;

	float planeA = texture2D(shadowcolor1, noiseCoord).a;
	float planeB = texture2D(shadowcolor1, noiseCoord + 0.25).a;

	return mix(planeA, planeB, fractPos.y);
}
#endif

void computeVolumetricClouds(inout vec4 vc, in float dither, in float ug) {
	//Depts
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	float visibility = ug * float(z0 > 0.56);

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

		float VoS = clamp(dot(normalize(viewPos.xyz), sunVec) * shadowFade, 0.0, 1.0);
		float lViewPos = length(viewPos);

		lightCol = mix(lightCol, skyColor * skyColor * 2.0, timeBrightness * (0.25 - rainStrength * 0.25));
		ambientCol = mix(ambientCol, skyColor * skyColor, sunVisibility * (0.125 - rainStrength * 0.125));
		lightCol *= 1.0 + pow2(VoS) * 0.5;

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

			if (lWorldPos > VC_DISTANCE || lViewPos < lWorldPos) break;

			float cloudLayer = abs(VC_HEIGHT - rayPos.y) / stretching;

			if (cloudLayer > 2.0) break;

			float cloudVisibility = float(cloudLayer < 2.0);

			//Indoor leak prevention
			if (eyeBrightnessSmooth.y <= 150.0) {
				vec3 shadowPos = calculateShadowPos(worldPos);
				float shadow1 = shadow2D(shadowtex1, shadowPos).z;

				cloudVisibility *= 1.0 - float(shadow1 != 1.0);
			}

			//Shaping & Lighting
			if (cloudVisibility > 0.0) {
				//Cloud Noise
				#ifndef BLOCKY_CLOUDS
				float noise = get3DNoise(rayPos * 0.5000 + frameTimeCounter * 0.20) * 1.25;
					  noise+= get3DNoise(rayPos * 0.2350 + frameTimeCounter * 0.15) * 1.75;
					  noise+= get3DNoise(rayPos * 0.1100 + frameTimeCounter * 0.10) * 3.50;
					  noise+= get3DNoise(rayPos * 0.0521 + frameTimeCounter * 0.05) * 6.75;
				#else
				float noise = get3DNoise(floor(rayPos) * 0.035) * 1000.0;
				#endif

				//noise = clamp(noise * amount - (10.0 + cloudLayer * 5.0), 0.0, 1.0);
				noise = clamp(noise * (VC_AMOUNT * (1.0 + rainStrength * 0.15)) - (10.0 + cloudLayer * 5.0), 0.0, 1.0);

				//Color Calculations
				float cloudLighting = clamp(smoothstep(VC_HEIGHT + stretching * noise, VC_HEIGHT - stretching * noise, rayPos.y) * 0.95 + noise * 0.35, 0.0, 1.0);
				#ifdef VC_DISTANT_FADE
				float cloudDistantFade = clamp((VC_DISTANCE - lWorldPos) / VC_DISTANCE * 3.0, 0.0, 1.0);
				#endif

				vec4 cloudColor = vec4(mix(lightCol, ambientCol, cloudLighting), noise);
					 cloudColor.rgb *= cloudColor.a;
					 #ifdef VC_DISTANT_FADE
					 cloudColor.a *= mix(0.0, 1.0, min(cloudDistantFade + 0.25, 1.0));
					 #endif

				vc += cloudColor * (1.0 - vc.a);
			}
		}

		vc *= ug;
	}
}
#endif

#ifdef VL
void computeVolumetricLight(inout vec3 vl, in vec3 translucent, in float dither) {
	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	//Positions
	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec3 nViewPos = normalize(viewPos.xyz);

	float VoU = max(dot(nViewPos, upVec), 0.0);
	float nVoU = pow2(1.0 - VoU);
		  nVoU = mix(0.5, nVoU, clamp(eBS - float(isEyeInWater == 1), 0.0, 1.0));

	float VoS = pow(clamp(dot(nViewPos, sunVec), 0.0, 1.0), 1.5);
	float nVoS = mix(0.3 + VoS * 0.7, VoS, timeBrightness);
		  nVoS = mix(0.5 + VoS * 0.5, nVoS, max(eBS - float(isEyeInWater == 1), 0.0));

	float visibility = float(z0 > 0.56) * nVoU * nVoS * 0.0125;

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		#ifdef SHADOW_COLOR
		vec3 shadowCol = vec3(0.0);
		#endif

		float lViewPos = length(viewPos);
		float linearDepth0 = getLinearDepth2(z0);
		float linearDepth1 = getLinearDepth2(z1);

		float distanceFactor = mix(7.0, 3.5, eBS);

		//Ray marching and main calculations
		for (int i = 0; i < VL_SAMPLES; i++) {
			float currentDepth = pow(i + dither + 0.75, 1.5) * distanceFactor;

			if (linearDepth1 < currentDepth || (linearDepth0 < currentDepth && translucent.rgb == vec3(0.0))) {
				break;
			}

			vec3 worldPos = calculateWorldPos(getLogarithmicDepth(currentDepth), texCoord);

			float lWorldPos = length(worldPos);

			if (nVoU == 0.0 || lWorldPos > far) break;

			vec3 shadowPos = calculateShadowPos(worldPos);

			if (length(shadowPos.xy * 2.0 - 1.0) < 1.0) {
				float shadow1 = shadow2D(shadowtex1, shadowPos).z;
				float shadow0 = shadow2D(shadowtex0, shadowPos).z;

				//Distant Fade
				float fogFade = 1.0 - clamp(pow4(lViewPos * 0.000125) + pow8(lWorldPos / far), 0.0, 1.0);
				visibility *= fogFade;

				//Colored Shadows


				vec3 shadow = clamp(shadowCol * (1.0 - shadow0) + shadow0, 0.0, 1.0);

				//Translucency Blending
				if (linearDepth0 < currentDepth) {
					shadow *= translucent.rgb;
				}

				vl += shadow;
			} else break;
		}

		vl *= visibility;
		vl *= mix(lightCol * (1.0 + VoS * 2.0), skyColor * skyColor, timeBrightness * 0.5) * VL_OPACITY;
	}
}
#endif