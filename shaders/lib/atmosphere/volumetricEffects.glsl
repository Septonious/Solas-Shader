#ifdef VC
int day = worldDay % 72 / 8 / 21;

float amount = mix(VC_AMOUNT * (1.0 + day), 2.0, rainStrength);

float get3DNoise(vec3 pos) {
	pos *= 0.4 + day;
	pos.xz *= 0.4;

	vec3 floorPos = floor(pos);
	vec3 fractPos = fract(pos);

	vec2 noiseCoord = (floorPos.xz + fractPos.xz + floorPos.y * 16.0) * 0.015625;

	float planeA = texture2D(noisetex, noiseCoord).r;
	float planeB = texture2D(noisetex, noiseCoord + 0.25).r;

	return mix(planeA, planeB, fractPos.y);
}

void computeVolumetricEffects(in vec2 newTexCoord, in float dither, in float ug, inout vec4 vlOut1, inout vec4 vlOut2) {
	float z0 = texture2D(depthtex0, newTexCoord).r;

	if (clamp(texCoord, 0.0, VOLUMETRICS_RESOLUTION + 1e-3) == texCoord && ug != 0.0 && z0 > 0.56) {
		vec4 vc = vec4(0.0);

		//Positions
		vec4 screenPos = vec4(newTexCoord, z0, 1.0);
		vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		viewPos /= viewPos.w;

		vec3 nWorldPos = normalize(mat3(gbufferModelViewInverse) * viewPos.xyz);

		float lViewPos = length(viewPos);

		//We want to march between two planes which we set here
		float lowerPlane = (VC_HEIGHT + VC_STRETCHING - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (VC_HEIGHT - VC_STRETCHING - cameraPosition.y) / nWorldPos.y;
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

			if (lWorldPos > VC_DISTANCE || lWorldPos > lViewPos) break;

			float cloudLayer = abs(VC_HEIGHT - rayPos.y) / VC_STRETCHING;

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
				float noise = get3DNoise(rayPos * 0.625 + frameTimeCounter * 0.20) * 1.0;
					  noise+= get3DNoise(rayPos * 0.250 + frameTimeCounter * 0.15) * 1.5;
					  noise+= get3DNoise(rayPos * 0.125 + frameTimeCounter * 0.10) * 3.0;
					  noise+= get3DNoise(rayPos * 0.025 + frameTimeCounter * 0.05) * 9.0;
				noise = clamp(noise * amount - (10.0 + cloudLayer * 5.0), 0.0, 1.0);

				//Color Calculations
				float cloudLighting = clamp(smoothstep(VC_HEIGHT + VC_STRETCHING * noise, VC_HEIGHT - VC_STRETCHING * noise, rayPos.y) * 0.5 + noise * 0.5, 0.0, 1.0);
				float cloudDistantFade = clamp((VC_DISTANCE - lWorldPos) / VC_DISTANCE, 0.125, 1.0);

				vec4 cloudColor = vec4(mix(lightCol, ambientCol, cloudLighting), noise * cloudDistantFade);
					 cloudColor.rgb *= cloudColor.a;

				vc += cloudColor * (1.0 - vc.a);
			}
		}

		//Why not tint out clouds with the sky color?
		vc.rgb = mix(vc.rgb, vc.rgb * 0.65, (1.0 - rainStrength) * (1.0 - timeBrightness));
		vc.rgb = mix(vc.rgb, vc.rgb * skyColor * skyColor * 2.0, timeBrightness * (1.0 - rainStrength));

		vlOut2 = pow(vc / 64.0, vec4(0.25)) * ug;
	}
}
#endif