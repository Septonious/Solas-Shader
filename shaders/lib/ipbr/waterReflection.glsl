void getReflection(sampler2D depthtex, inout vec4 albedo, in vec3 viewPos, in vec3 normal, in float fresnel, in float skyLightMap, in float water, inout float emission) {
	vec3 nViewPos = normalize(viewPos);
	vec3 reflectedViewPos = reflect(nViewPos, normal);

	float border = 0.0;
	float dither = Bayer64(gl_FragCoord.xy);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

	vec3 reflectPos = rayTrace(depthtex, viewPos, normal, dither, border, 4, 12, 0.1, 2.0);
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
			#ifdef OVERWORLD
			float sunMoon = 0.0;

			reflectionFade = getAtmosphere(reflectedViewPos);
			reflectionFade *= skyLightMap;
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