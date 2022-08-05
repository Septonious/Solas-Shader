vec3 getReflection(vec3 viewPos, vec3 normal, vec3 color) {
	vec3 reflectedViewPos = reflect(normalize(viewPos), normal);
	vec3 reflectedScreenPos = ToScreen(reflectedViewPos);
	vec3 reflection = vec3(0.0);

	#if REFLECTION_TYPE == 0
    bool outsideScreen = !(any(lessThan(reflectedScreenPos.xy, vec2(0.0))) || any(greaterThan(reflectedScreenPos.xy, vec2(1.0))));
	#elif REFLECTION_TYPE == 1
	bool outsideScreen = rayTrace(viewPos, reflectedViewPos, reflectedScreenPos);
	#endif

    #if defined OVERWORLD || defined END
    float nebulaFactor = 0.0;
    float blackHoleFactor = 0.0;
    #endif

	#if defined OVERWORLD
	vec3 reflectionFade = color;

    if (eBS != 0.0) {
        vec3 nViewPos = normalize(reflectedViewPos);
        vec3 worldPos = mat3(gbufferModelViewInverse) * reflectedViewPos;
        float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
        float VoM = clamp(dot(nViewPos, -sunVec), 0.0, 1.0);
        float VoU = dot(nViewPos, upVec);

        reflectionFade = getAtmosphere(reflectedViewPos);

		#ifdef STARS
		getStars(reflectionFade, worldPos, VoU, nebulaFactor, 0.0, ug);
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

		getSunMoon(reflectionFade, nViewPos, lightSun, lightNight, VoS, VoM, VoU, ug);
    }
    
	reflectionFade *= eBS;

	#elif defined NETHER
	vec3 reflectionFade = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 reflectionFade = endLightCol * 0.15;

	if (eBS != 0.0) {
		#if defined END_NEBULA || defined END_STARS
		vec3 worldPos = mat3(gbufferModelViewInverse) * reflectedViewPos;
		vec3 nViewPos = normalize(reflectedViewPos);

		float VoU = dot(nViewPos, upVec);
		#endif

		#ifdef END_NEBULA
		getNebula(reflectionFade, worldPos, VoU, nebulaFactor, 1.0);
		#endif

		#ifdef END_STARS
		getStars(reflectionFade, worldPos, VoU, nebulaFactor, blackHoleFactor, 1.0);
		#endif
	}

	reflectionFade *= eBS;
	#endif

    if (outsideScreen) {
        reflection = texture2D(colortex6, reflectedScreenPos.xy).rgb;
    }

    #if MC_VERSION >= 11900
    reflectionFade *= 1.0 - darknessFactor;
    #endif

    reflectionFade *= 1.0 - blindFactor;

    return mix(reflectionFade, reflection, float(reflection != vec3(0.0)));
}