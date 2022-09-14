void getReflection(in float fresnel, in float skyLightMap, in vec3 viewPos, in vec3 normal, inout vec3 color) {
	vec3 reflectedViewPos = reflect(normalize(viewPos), normal);
	vec3 reflectedScreenPos = ToScreen(reflectedViewPos);
	vec3 reflection = vec3(0.0);

	skyLightMap *= pow32(skyLightMap);

	#if REFLECTION_TYPE == 0
    bool outsideScreen = !(any(lessThan(reflectedScreenPos.xy * 100.0, vec2(0.0))) || any(greaterThan(reflectedScreenPos.xy * 100.0, vec2(1.0))));
	#elif REFLECTION_TYPE == 1
	bool outsideScreen = rayTrace(viewPos, reflectedViewPos, reflectedScreenPos);
	#endif

    #if defined OVERWORLD || defined END
    float nebulaFactor = 0.0;
    #endif

	#if defined OVERWORLD
	vec3 reflectionFade = color;

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
    }
    
	reflectionFade *= skyLightMap;

	#elif defined NETHER
	vec3 reflectionFade = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 reflectionFade = endLightCol * 0.15;

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
		#endif

		#ifdef END_VORTEX
		getEndVortex(reflectionFade, worldPos, VoU, VoS);
		#endif
	}

	reflectionFade *= skyLightMap;
	#endif

    if (outsideScreen) {
        reflection = texture2D(gaux3, reflectedScreenPos.xy).rgb;
    }

    #if MC_VERSION >= 11900
    reflectionFade *= 1.0 - darknessFactor;
    #endif

    reflectionFade *= 1.0 - blindFactor;

	//fresnel = mix(fresnel * 0.75, fresnel, float(reflection != vec3(0.0)));
	color = mix(color, mix(reflectionFade, reflection, float(reflection != vec3(0.0))), fresnel);
}