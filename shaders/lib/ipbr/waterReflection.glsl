void getReflection(inout vec4 color, in vec3 viewPos, in vec3 normal, in float fresnel, in float skyLightMap, inout float emission) {
	vec3 nViewPos = normalize(viewPos);
	vec3 reflectedViewPos = reflect(nViewPos, normal);

	float border = 0.0;
	float dither = Bayer64(gl_FragCoord.xy);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

	vec3 reflectPos = rayTrace(viewPos, normal, dither, border, 4, 1.0, 0.1, 2.0);
	vec4 reflection = vec4(0.0);

	border = clamp(13.333 * (1.0 - border), 0.0, 1.0);

	if (reflectPos.z < 1.0 - 1e-5) {
		reflection.a = texture2D(gaux3, reflectPos.xy).a;
		if (reflection.a > 0.001) {
			reflection.rgb = texture2D(gaux3, reflectPos.xy).rgb;
		}
		reflection.a *= border;
	}

	#ifdef OVERWORLD
	vec3 reflectionFade = color.rgb;
	#elif defined NETHER
	vec3 reflectionFade = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 reflectionFade = endLightCol * 0.15;
	#endif

	if (reflection.a < 1.0) {
		#if defined OVERWORLD || defined END
		float nebulaFactor = 0.0;
		#endif

		#if defined OVERWORLD
		if (skyLightMap != 0.0) {
			vec3 nViewPos = normalize(reflectedViewPos);
			vec3 worldPos = mat3(gbufferModelViewInverse) * reflectedViewPos;
			float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
			float VoM = clamp(dot(nViewPos, -sunVec), 0.0, 1.0);
			float VoU = dot(nViewPos, upVec);

			reflectionFade = getAtmosphere(reflectedViewPos);

			#ifdef STARS
			float star = 0.0;
			getStars(reflectionFade, worldPos, VoU, nebulaFactor, ug, star);
			emission += star * 32.0;
			#endif

			if (VoU > 0.0) {
				VoU = sqrt(VoU);

				#ifdef RAINBOW
				getRainbow(reflectionFade, worldPos, VoU, 1.75, 0.05, ug);
				#endif

				#ifdef AURORA
				getAurora(reflectionFade, worldPos, ug);
				#endif
			}

			float sunMoon = 0.0;
			getSunMoon(reflectionFade, nViewPos, lightSun, lightNight, VoS, VoM, VoU, ug, sunMoon);
			emission += sunMoon * 0.25;

			reflectionFade *= skyLightMap;
		}

		#elif defined END
		if (skyLightMap != 0.0) {
			#if defined END_NEBULA || defined END_STARS
			vec3 worldPos = mat3(gbufferModelViewInverse) * reflectedViewPos;
			vec3 nViewPos = normalize(reflectedViewPos);
			float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
			float VoU = dot(nViewPos, upVec);
			#endif

			#ifdef END_NEBULA
			getNebula(reflectionFade, worldPos, VoU, nebulaFactor, 1.0);
			#endif

			#ifdef END_STARS
			float star = 0.0;
			getStars(reflectionFade, worldPos, VoU, nebulaFactor, 1.0, star);
			emission += star * 32.0;
			#endif

			#ifdef END_VORTEX
			getEndVortex(reflectionFade, worldPos, VoU, VoS);
			#endif

			reflectionFade *= skyLightMap;
		}
		#endif

		#if MC_VERSION >= 11900
		reflectionFade *= 1.0 - darknessFactor;
		#endif

		reflectionFade *= 1.0 - blindFactor;

		reflectionFade = mix(color.rgb, reflectionFade, skyLightMap);
	}

	vec3 finalReflection = max(mix(reflectionFade, reflection.rgb, reflection.a), vec3(0.0));
			
	color.rgb = mix(color.rgb, finalReflection, min(fresnel * 2.0, 1.0) * WATER_SPECULAR_STRENGTH);
	color.a = mix(color.a, 1.0, fresnel);
}