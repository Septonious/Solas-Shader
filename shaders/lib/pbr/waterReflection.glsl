void getReflection(inout vec4 albedo, in vec3 viewPos, in vec3 nViewPos, in vec3 normal, in float fresnel, in float skyLightMap) {
	vec3 reflectedViewPos = reflect(nViewPos, normal);

	float border = 0.0;
	float dither = Bayer8(gl_FragCoord.xy);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

	vec4 reflectPos = rayTrace(depthtex1, viewPos, normal, dither, border, 3, 16, 0.2, 1.5);

	border = clamp(13.333 * (1.0 - border), 0.0, 1.0);

	vec4 reflection = texture2D(gaux3, reflectPos.xy);
	     reflection.rgb = pow8(reflection.rgb * 2.0);
	     reflection.a *= border;
         reflection.rgb *= float(reflection.a > 0.0);

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
	        vec3 sunPos = vec3(gbufferModelViewInverse * vec4(sunVec * 128.0, 1.0));
	        vec3 sunCoord = sunPos / (sunPos.y + length(sunPos.xz));
            reflectionFade = getAtmosphericScattering(normalize(ToWorld(reflectedViewPos)) * PI, reflectedViewPos, normalize(sunCoord));
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

	albedo.rgb = mix(albedo.rgb, finalReflection, fresnel);
}