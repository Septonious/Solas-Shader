void getReflection(inout vec4 albedo, in vec3 viewPos, in vec3 normal, in float fresnel, in float skyLightMap, in float water, inout float emission) {
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

	reflection.a = texture2D(gaux3, reflectPos.xy).a;
	if (reflection.a > 0.0) {
		reflection.rgb = texture2D(gaux3, reflectPos.xy).rgb;
		reflection.rgb = pow8(reflection.rgb * 2.0);
	}
	reflection.a *= border;

	#ifdef OVERWORLD
	vec3 reflectionFade = albedo.rgb;
	#elif defined NETHER
	vec3 reflectionFade = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 reflectionFade = endLightCol * 0.15;
	#endif

	if (reflection.a < 1.0) {
		if (skyLightMap > 0.0) {
			#if defined OVERWORLD || (defined END && (defined END_NEBULA || defined END_STARS))
			float nebulaFactor = 0.0;
			float endVortex = 0.0;
			float sunMoon = 0.0;
			float star = 0.0;

			vec3 worldPos = mat3(gbufferModelViewInverse) * reflectedViewPos;
			vec3 nViewPos = normalize(reflectedViewPos);
			float VoU = dot(nViewPos, upVec);
			float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
			float VoM = clamp(dot(nViewPos, -sunVec), 0.0, 1.0);
			#endif

			#if defined OVERWORLD
			reflectionFade = getAtmosphere(reflectedViewPos);

			if (VoU > 0.0) {
				VoU = pow2(VoU);

				#ifdef STARS
				getStars(reflectionFade, worldPos, VoU, nebulaFactor, caveFactor);
				#endif
					
				#ifdef RAINBOW
				getRainbow(reflectionFade, worldPos, VoU, 1.75, 0.05, caveFactor);
				#endif

				#ifdef AURORA
				getAurora(reflectionFade, worldPos, caveFactor, dither);
				#endif
			}

			//Increasing sun/moon reflections intensity
			#ifdef WATER_NORMALS
			lightSun *= 3.0;
			lightNight *= 2.0;
			#endif

			getSunMoon(reflectionFade, nViewPos, lightSun, lightNight, VoS, VoM, caveFactor, sunMoon);
			reflectionFade *= skyLightMap;

			#elif defined END
			#ifdef END_NEBULA
			getNebula(reflectionFade, worldPos, VoU, nebulaFactor, 1.0);
			#endif

			#ifdef END_STARS
			getStars(reflectionFade, worldPos, VoU, nebulaFactor, 1.0);
			#endif

			#ifdef END_VORTEX
			getEndVortex(reflectionFade, worldPos, VoU, VoS);
			#endif
			#endif
		}

		#if MC_VERSION >= 11900
		reflectionFade *= 1.0 - darknessFactor;
		#endif

		reflectionFade *= 1.0 - blindFactor;

		#ifdef OVERWORLD
		reflectionFade = mix(albedo.rgb, reflectionFade, skyLightMap);
		#endif
	}

	vec3 finalReflection = max(mix(reflectionFade, reflection.rgb, reflection.a), vec3(0.0));

	albedo.rgb = mix(albedo.rgb, finalReflection, fresnel * WATER_SPECULAR_STRENGTH * (1.0 - sign(isEyeInWater) * 0.75) * (0.25 + water * 0.75));
}