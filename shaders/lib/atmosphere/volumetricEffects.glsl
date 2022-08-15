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

void computeVolumetricClouds(inout vec4 vc, in vec3 playerPos, in float lWorldPos, in float vcLayer) {
	//Cloud Noise
	float noise = get3DNoise(playerPos * 0.625 + frameTimeCounter * 0.20) * 1.0;
		  noise+= get3DNoise(playerPos * 0.250 + frameTimeCounter * 0.15) * 1.5;
		  noise+= get3DNoise(playerPos * 0.125 + frameTimeCounter * 0.10) * 3.0;
		  noise+= get3DNoise(playerPos * 0.025 + frameTimeCounter * 0.05) * 9.0;

	noise = clamp(noise * amount - (10.0 + vcLayer * 5.0), 0.0, 1.0);

	//Color Calculations
	float cloudLighting = clamp(smoothstep(VC_HEIGHT + VC_STRETCHING * noise, VC_HEIGHT - VC_STRETCHING * noise, playerPos.y) * 0.5 + noise * 0.5, 0.0, 1.0);
	vec4 cloudColor = vec4(mix(lightCol, ambientCol, cloudLighting), noise);
		 cloudColor.rgb *= cloudColor.a;

	vc += cloudColor * (1.0 - vc.a);
}
#endif

#ifdef VL
void computeVolumetricLight(inout vec4 vl, in vec3 shadowPos, in float shadow1, in float lViewPos, in float lWorldPos, in float vlVisibility) {
	//Distant Fade for VL
	float vlDistantFade = 1.0 - clamp(pow4(lViewPos * 0.000125) + pow8(lWorldPos / far), 0.0, 1.0);

	//Colored Shadows
	#ifdef SHADOW_COLOR
	float shadow0 = shadow2D(shadowtex0, shadowPos).z;
	vec3 shadowCol = vec3(0.0);

	if (shadow0 < 1.0) {
		if (shadow1 > 0.0) {
			shadowCol = texture2D(shadowcolor0, shadowPos.xy).rgb;
			shadowCol *= shadowCol * shadow1;
		}
	}

	vec3 shadow = clamp(shadowCol * 24.0 * (1.0 - shadow0) + shadow0, 0.0, 24.0);
	#endif

	//Color Calculations
	vlVisibility *= vlDistantFade;

	vec4 vlColor = vec4(mix(lightCol, waterColor, float(isEyeInWater == 1)), vlVisibility);
		 vlColor.rgb *= vlColor.a;

		 #ifdef SHADOW_COLOR
		 vlColor.rgb *= shadow;
		 #endif

	vl += vlColor * (1.0 - vl.a);
}
#endif

void computeVolumetricEffects(vec2 newTexCoord, float dither, float ug, inout vec4 vlOut1, inout vec4 vlOut2) {
	if (clamp(texCoord, 0.0, VOLUMETRICS_RESOLUTION + 1e-3) == texCoord && ug != 0.0) {
		vec4 vl = vec4(0.0);
		vec4 vc = vec4(0.0);

		float z0 = texture2D(depthtex0, newTexCoord).r;

		vec4 screenPos = vec4(newTexCoord, z0, 1.0);
		vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		viewPos /= viewPos.w;

		vec3 nWorldPos = normalize(mat3(gbufferModelViewInverse) * viewPos.xyz);
		vec3 rayPos = cameraPosition + nWorldPos;
		vec3 increment = nWorldPos * VC_DISTANCE;
		rayPos += increment * dither;

		#ifdef VL
		float vlVisibility = float(z0 > 0.56) * (1.0 - timeBrightness * 0.75) * VL_OPACITY;
		#endif

		float lViewPos = length(viewPos.xz);

		for (int i = 0; i < VC_SAMPLES; i++) {
			rayPos += increment;
			vec3 traceWorldPos = rayPos - cameraPosition;

			float lWorldPos = length(traceWorldPos);

			if (lWorldPos > 1024.0) break;
        	if (lWorldPos > lViewPos) continue;

			vec3 shadowPos = calculateShadowPos(traceWorldPos);

			float shadow1 = shadow2D(shadowtex1, shadowPos).z;
			float vcLayer = abs(VC_HEIGHT - rayPos.y) / VC_STRETCHING;
			float vlLayer = 1.0 - clamp(pow16((rayPos.y + 1000.0 - VL_HEIGHT) * 0.001), 0.0, 1.0);

			#ifndef VC
			vcLayer = 3.0;
			#endif

			#ifndef VL
			vlLayer = 0.0;
			#endif

			float totalVisibility = (1.0 - float(shadow1 != 1.0) * float(eyeBrightnessSmooth.y <= 150.0)) * float(vcLayer < 2.0 || vlLayer > 0.0);

			if (totalVisibility > 0.5) {
				//Volumetric Light
				#ifdef VL
				computeVolumetricLight(vl, shadowPos, shadow1, lViewPos, lWorldPos, vlVisibility * vlLayer);
				#endif

				//Volumetric Clouds
				#ifdef VC
				computeVolumetricClouds(vc, rayPos, lWorldPos, vcLayer);
				#endif
			}
		}

		#ifdef VC
		vc.rgb = mix(vc.rgb, vc.rgb * 0.65, (1.0 - rainStrength) * (1.0 - timeBrightness));
		vc.rgb = mix(vc.rgb, vc.rgb * skyColor * skyColor * 2.0, timeBrightness * (1.0 - rainStrength));
		#endif

		vlOut1 = vl;
		vlOut2 = vc;
	}
}