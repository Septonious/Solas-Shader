void getReflection(inout vec4 albedo, in vec3 viewPos, in vec3 newNormal, in float fresnel, in float skyLightMap) {
	float dither = Bayer8(gl_FragCoord.xy);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

    float border = 0.0;
    vec2 cdist = vec2(0.0);

    vec3 reflectPos = Raytrace(depthtex1, viewPos, newNormal, dither, 6, 1.0, 0.1, 1.6, border, cdist);

	float zThreshold = 1.0;

	float borderFade = clamp(13.333 * (1.0 - border), 0.0, 1.0);
	vec2 edgeFactor = pow4(cdist);
	float screenFade = pow(max((1.0 - edgeFactor.x) * (1.0 - edgeFactor.y), 0.0), 2.0);
	borderFade *= screenFade;

	vec4 reflection = vec4(0.0);
	if (reflectPos.z < zThreshold && borderFade > 0.001 &&
		reflectPos.x > 0.0 && reflectPos.x < 1.0 &&
		reflectPos.y > 0.0 && reflectPos.y < 1.0) {
		reflection = texture(gaux1, reflectPos.xy);
		reflection.rgb = min(pow8(reflection.rgb) * 256.0, vec3(4.0));
		reflection.a = borderFade;
	}

	#ifdef OVERWORLD
	vec3 falloff = albedo.rgb;
	#elif defined NETHER
	vec3 falloff = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 falloff = endAmbientColSqrt * 0.25;
	#endif

	if (reflection.a < 1.0 && isEyeInWater == 0) {
		if (skyLightMap > 0.95) {
			#ifdef OVERWORLD
			vec3 viewPosRef = reflect(normalize(viewPos), newNormal);
			vec3 worldPosRef = ToWorld(viewPosRef);
            float atmosphereHardMixFactor = 0.0;
			vec3 reflectedAtmosphere = getAtmosphere(viewPosRef.xyz, worldPosRef.xyz, atmosphereHardMixFactor);

			float waterSkyOcclusion = skyLightMap;
			#if REFLECTION_SKY_FALLOFF > 1
			waterSkyOcclusion = clamp(1.0 - (1.0 - waterSkyOcclusion) * REFLECTION_SKY_FALLOFF, 0.0, 1.0);
			#endif
			waterSkyOcclusion *= waterSkyOcclusion;

			falloff = mix(falloff, reflectedAtmosphere, waterSkyOcclusion);
			#endif
		}

		#if MC_VERSION >= 11900
		falloff *= 1.0 - darknessFactor;
		#endif

		falloff *= 1.0 - blindFactor;
	}

	vec3 finalReflection = max(mix(falloff, reflection.rgb, reflection.a), vec3(0.0));

	albedo.rgb = mix(albedo.rgb, finalReflection, fresnel);
}
