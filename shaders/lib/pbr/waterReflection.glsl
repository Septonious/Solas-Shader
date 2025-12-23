void getReflection(inout vec4 albedo, in vec3 viewPos, in vec3 nViewPos, in vec3 normal, in float fresnel, in float skyLightMap) {
	float dither = Bayer8(gl_FragCoord.xy);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

    float border = 0.0;
    float lRfragPos = 0.0;
    float dist = 0.0;
    vec2 cdist = vec2(0.0);

    #if !defined DH_WATER && !defined VOXY_TRANSLUCENT
        #if WATER_NORMALS > 0
        vec3 reflectPos = Raytrace(depthtex1, viewPos, normal, dither, fresnel, 6, 1.0, 0.1, 1.6, 10, border, lRfragPos, dist, cdist);
        #else
        vec3 reflectPos = Raytrace(depthtex1, viewPos, normal, dither, fresnel, 6, 1.0, 0.4, 1.4, 30, border, lRfragPos, dist, cdist);
        #endif
    #elif defined DH_WATER
        #if WATER_NORMALS > 0
        vec3 reflectPos = Raytrace(dhDepthTex1, viewPos, normal, dither, fresnel, 6, 1.0, 0.1, 1.6, 10, border, lRfragPos, dist, cdist);
        #else
        vec3 reflectPos = Raytrace(dhDepthTex1, viewPos, normal, dither, fresnel, 6, 1.0, 0.4, 1.4, 30, border, lRfragPos, dist, cdist);
        #endif
    #elif defined VOXY_TRANSLUCENT
        #if WATER_NORMALS > 0
        vec3 reflectPos = Raytrace(vxDepthTexTrans, viewPos, normal, dither, fresnel, 6, 1.0, 0.1, 1.6, 10, border, lRfragPos, dist, cdist);
        #else
        vec3 reflectPos = Raytrace(vxDepthTexTrans, viewPos, normal, dither, fresnel, 6, 1.0, 0.4, 1.4, 30, border, lRfragPos, dist, cdist);
        #endif
    #endif

	float zThreshold = 1.0 + 1e-5;
	vec4 reflection = vec4(0);
	if (reflectPos.z < zThreshold) {
		reflection = texture2D(gaux1, reflectPos.xy);
		reflection.rgb = pow8(reflection.rgb) * 256.0;
		reflection.rgb *= float(reflection.a > 0.0);
		reflection.a *= border;
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
			vec3 viewPosRef = reflect(normalize(viewPos), normal);
			vec3 reflectedAtmosphere = getAtmosphere(viewPosRef);
			falloff = mix(falloff, reflectedAtmosphere, skyLightMap);
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