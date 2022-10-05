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

float getCloudNoise(vec3 rayPos) {
	#ifndef BLOCKY_CLOUDS
	float noise = get3DNoise(rayPos * 0.5000 + frameTimeCounter * 0.20) * 1.25;
		  noise+= get3DNoise(rayPos * 0.2500 + frameTimeCounter * 0.15) * 1.75;
		  noise+= get3DNoise(rayPos * 0.1250 + frameTimeCounter * 0.10) * 3.50;
		  noise+= get3DNoise(rayPos * 0.0625 + frameTimeCounter * 0.05) * 6.75;
	#else
	float noise = get3DNoise(floor(rayPos) * 0.035) * 1000.0;
	#endif

	return noise;
}

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

		float VoL = clamp(dot(normalize(viewPos.xyz), lightVec) * shadowFade, 0.0, 1.0);
		float lViewPos = length(viewPos);

		ambientCol = mix(ambientCol, skyColor, sunVisibility * 0.2 * (1.0 - rainStrength * 0.75));
		lightCol *= 1.0 + pow4(VoL);

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
				float noise = getCloudNoise(rayPos);
					  noise = clamp(noise * (VC_AMOUNT * (1.0 + rainStrength * 0.15)) - (8.0 + cloudLayer * 3.0), 0.0, 1.0);

				//Color Calculations
				float cloudLighting = clamp(smoothstep(VC_HEIGHT + stretching * noise, VC_HEIGHT - stretching * noise, rayPos.y) * 0.7 + noise * 0.5, 0.0, 1.0);

				#ifdef VC_DISTANT_FADE
				float cloudDistantFade = clamp((VC_DISTANCE - lWorldPos) / VC_DISTANCE * 3.0, 0.0, 1.0);
				#endif

				vec4 cloudColor = vec4(mix(lightCol, ambientCol, cloudLighting), noise);
					 #ifdef VC_DISTANT_FADE
					 cloudColor.a *= mix(0.0, 1.0, min(cloudDistantFade + 0.25, 1.0));
					 #endif
					 cloudColor.rgb *= cloudColor.a;

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
	float nVoU = pow3(1.0 - VoU);

	vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
	float VoL = pow(clamp(dot(nViewPos, lightVec), 0.0, 1.0), 1.25);
	float nVoL = mix(0.5 + VoL * 0.5, VoL, timeBrightness);

	float visibility = float(z0 > 0.56) * mix(nVoU * nVoL, 1.0, sign(isEyeInWater)) * 0.01;

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

		float distanceFactor = 2.0 + eBS * (4.0 - float(isEyeInWater == 1) * 4.0);

		//Ray marching and main calculations
		for (int i = 0; i < VL_SAMPLES; i++) {
			float currentDepth = pow(i + dither + 0.5 - float(isEyeInWater == 1) * 0.5, 1.5) * distanceFactor;

			if (linearDepth1 < currentDepth || (linearDepth0 < currentDepth && translucent.rgb == vec3(0.0))) {
				break;
			}

			vec3 worldPos = calculateWorldPos(getLogarithmicDepth(currentDepth), texCoord);

			float lWorldPos = length(worldPos);

			if (nVoU == 0.0 || lWorldPos > far) break;

			vec3 shadowPos = calculateShadowPos(worldPos);
			shadowPos.z += 0.0512 / shadowMapResolution;

			if (length(shadowPos.xy * 2.0 - 1.0) < 1.0) {
				float shadow0 = shadow2D(shadowtex0, shadowPos).z;

				//Colored Shadows
				#ifdef SHADOW_COLOR
				if (shadow0 < 1.0) {
					float shadow1 = shadow2D(shadowtex1, shadowPos.xyz).z;
					if (shadow1 > 0.0) {
						shadowCol = texture2D(shadowcolor0, shadowPos.xy).rgb;
						shadowCol *= shadowCol * shadow1;
					}
				}
				#endif
				vec3 shadow = clamp(shadowCol * (1.0 + float(isEyeInWater == 1) * 32.0) * (1.0 - shadow0) + shadow0, vec3(0.0), vec3(1.0));

				//Translucency Blending
				if (linearDepth0 < currentDepth) {
					shadow *= translucent.rgb;
				}

				vl += shadow;
			} else vl += 1.0;
		}

		vl *= visibility;
		vl *= lightCol * (1.0 + pow8(VoL)) * VL_OPACITY;
	}
}
#endif