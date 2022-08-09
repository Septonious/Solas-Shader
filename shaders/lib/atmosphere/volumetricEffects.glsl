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

float getCloudSample(vec3 pos, float cloudLayer) {
	float noise = get3DNoise(pos * 0.625 + frameTimeCounter * 0.20) * 1.0;
		  noise+= get3DNoise(pos * 0.250 + frameTimeCounter * 0.15) * 1.5;
		  noise+= get3DNoise(pos * 0.125 + frameTimeCounter * 0.10) * 3.0;
		  noise+= get3DNoise(pos * 0.025 + frameTimeCounter * 0.05) * 9.0;

	return clamp(noise * amount - (10.0 + cloudLayer * 5.0), 0.0, 1.0);
}
#endif

void computeVolumetricEffects(vec4 translucent, vec3 viewPos, vec2 newTexCoord, float z0, float z1, float dither, float ug, inout vec4 vlOut1, inout vec4 vlOut2) {
	if (clamp(texCoord, 0.0, VOLUMETRICS_RESOLUTION + 1e-3) == texCoord && ug != 0.0) {
		vec4 vl = vec4(0.0);
		vec4 vc = vec4(0.0);

		float linearDepth0 = getLinearDepth2(z0);
		float linearDepth1 = getLinearDepth2(z1);

		#ifdef VL
		vec3 shadowCol = vec3(0.0);

		float VoS = clamp(dot(normalize(viewPos), sunVec), -0.5, 0.0);
		float vlVisibility = float(z0 > 0.56) * (0.2 - timeBrightness * 0.1) * (1.0 + VoS);
		#endif

		float lViewPos = length(viewPos.xz) * 0.000125;

		float end = min(VC_DISTANCE * far, 2048.0);
		float start = dither * VC_QUALITY;

		for (start; start < end; start += VC_QUALITY) {
			if (linearDepth1 < start || (linearDepth0 < start && translucent.rgb == vec3(0.0)) || vc.a > 0.99 || vl.a > 0.99) {
				break;
			}

			vec3 worldPos = calculateWorldPos(getLogarithmicDepth(start), newTexCoord);
			vec3 shadowPos = calculateShadowPos(worldPos);
			vec3 playerPos = worldPos + cameraPosition;

			#ifdef VL
			float shadow0 = shadow2D(shadowtex0, shadowPos).z;
			#endif

			float shadow1 = shadow2D(shadowtex1, shadowPos).z;
			float lWorldPos = length(worldPos.xz);

			float vlLayer = 1.0 - clamp(playerPos.y * 0.001 * VL_HEIGHT, 0.0, 1.0);
			float cloudLayer = abs(VC_HEIGHT - playerPos.y) / VC_STRETCHING;
			float totalVisibility = (1.0 - float(shadow1 != 1.0) * float(eyeBrightnessSmooth.y <= 150.0)) * float(lWorldPos < end) * float(cloudLayer < 2.0 || vlLayer > 0.0);

			if (totalVisibility > 0.5) {
				//Volumetric Light
				#ifdef VL
				//Distant Fade for VL
				float vlDistantFade = 1.0 - clamp(pow4(lViewPos) + pow8(lWorldPos / far), 0.0, 1.0);

				//Colored Shadows
				#ifdef SHADOW_COLOR
				if (shadow0 < 1.0) {
					if (shadow1 > 0.0) {
						shadowCol = texture2D(shadowcolor0, shadowPos.xy).rgb;
						shadowCol *= shadowCol * shadow1;
					}
				}

				vec3 shadow = clamp(shadowCol * (8.0 + timeBrightness * 16.0) * (1.0 - shadow0) + shadow0, 0.0, 8.0 + timeBrightness * 16.0);
				#endif

				//Color Calculations
				vlVisibility *= vlDistantFade;

				vec4 vlColor = vec4(0.0);
				if (vlVisibility > 0.0 && vlLayer > 0.0 && shadow1 != 0.0) {
					vlColor = vec4(mix(lightCol, waterColor, float(isEyeInWater == 1)), vlLayer * vlVisibility);
					vlColor.rgb *= vlVisibility * vlLayer;

					#ifdef SHADOW_COLOR
					vlColor.rgb *= shadow;
					#endif
				}
				#endif

				//Volumetric Clouds
				#ifdef VC
				//Cloud Noise
				float noise = getCloudSample(playerPos, cloudLayer);

				//Distant Fade for Clouds
				float cloudDistantFade = clamp((end - lWorldPos) / end, 0.0, 1.0);

				//Color Calculations
				float cloudLighting = clamp(smoothstep(VC_HEIGHT + VC_STRETCHING * noise, VC_HEIGHT - VC_STRETCHING * noise, playerPos.y) * 0.4 + noise * 0.6, 0.0, 1.0);
				vec4 cloudColor = vec4(mix(lightCol, ambientCol, cloudLighting), noise);
					 cloudColor.rgb *= cloudColor.a;
					 cloudColor.a *= pow(cloudDistantFade, 0.125);
				#endif

				//Trabslucency Blending
				if (linearDepth0 < start) {
					#ifdef VL
					vlColor.rgb *= translucent.rgb * translucent.rgb;
					#endif

					#ifdef VC
					cloudColor.rgb *= translucent.rgb * translucent.rgb;
					#endif
				}

				//Accumulate Color
				#ifdef VL
				vl += vlColor * (1.0 - vl.a);
				#endif

				#ifdef VC
				vc += cloudColor * (1.0 - vc.a);
				#endif
			}
		}

		#ifdef VC
		vc.rgb = mix(vc.rgb, vc.rgb * 0.5, (1.0 - rainStrength) * (1.0 - timeBrightness));
		vc.rgb = mix(vc.rgb, vc.rgb * skyColor * skyColor * 2.0, timeBrightness * (1.0 - rainStrength));
		#endif

		vlOut1 = vl;
		vlOut2 = vc;
	}
}