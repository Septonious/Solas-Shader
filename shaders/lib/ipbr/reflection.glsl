vec3 getReflection(vec3 viewPos, vec3 normal, in vec3 color) {
	float roughness = texture2D(colortex6, texCoord).a * 100.0;
	vec3 reflectedVector = reflect(normalize(viewPos), normal) * 100.0;
	vec3 reflectedScreenPos = ToScreen(reflectedVector);
	vec3 reflection = vec3(0.0);

	#if REFLECTION_TYPE == 0
    bool outsideScreen = !(any(lessThan(reflectedScreenPos.xy, vec2(0.0))) || any(greaterThan(reflectedScreenPos.xy, vec2(1.0))));
	#elif REFLECTION_TYPE == 1
	bool outsideScreen = rayTrace(viewPos, reflectedVector, reflectedScreenPos);
	#endif

    #if defined OVERWORLD || defined END
    float nebulaFactor = 0.0;
    float blackHoleFactor = 0.0;
    #endif

	#if defined OVERWORLD
	vec3 reflectionFade = color;

    if (eBS != 0.0 && roughness == 0.0) {
        vec3 nViewPos = normalize(reflectedVector);
        vec3 worldPos = mat3(gbufferModelViewInverse) * reflectedVector;
        float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
        float VoM = clamp(dot(nViewPos, -sunVec), 0.0, 1.0);
        float VoU = dot(nViewPos, upVec);

        reflectionFade = getAtmosphere(reflectedVector);

		#ifdef NEBULA
		getNebula(reflectionFade, worldPos, VoU, nebulaFactor);
		#endif

		#ifdef STARS
		getStars(reflectionFade, worldPos, VoU, nebulaFactor, 0.0);
		#endif

		if (VoU > 0.0) {
			VoU = sqrt(VoU);

			#ifdef RAINBOW
			getRainbow(reflectionFade, worldPos, VoU, 1.75, 0.05);
			#endif

			#ifdef AURORA
			getAurora(reflectionFade, worldPos);
			#endif
		}

		if (roughness == 0.0) getSunMoon(reflectionFade, nViewPos, lightSun, lightNight, VoS, VoM, VoU, ug);
    }
    
	reflectionFade *= eBS;

	#elif defined NETHER
	vec3 reflectionFade = netherColSqrt.rgb * 0.15;
	#elif defined END
	vec3 reflectionFade = endLightCol * 0.15;

	if (roughness == 0.0 && eBS != 0.0) {
		#if defined END_NEBULA || defined END_BLACK_HOLE || defined END_STARS
		vec3 worldPos = mat3(gbufferModelViewInverse) * reflectedVector;
		vec3 nViewPos = normalize(reflectedVector);

		#ifdef END_BLACK_HOLE
		float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
		#endif

		float VoU = dot(nViewPos, upVec);
		#endif

		#ifdef END_NEBULA
		getNebula(reflectionFade, worldPos, VoU, nebulaFactor);
		#endif

		#ifdef END_BLACK_HOLE
		getBlackHole(reflectionFade, worldPos, VoS, VoU, blackHoleFactor);
		#endif

		#ifdef END_STARS
		getStars(reflectionFade, worldPos, VoU, nebulaFactor, blackHoleFactor);
		#endif
	}

	reflectionFade *= eBS;
	#endif

    if (outsideScreen){
        reflection = texture2DLod(colortex6, reflectedScreenPos.xy, roughness).rgb;
		reflection = pow(reflection, vec3(2.2));
    }

	vec3 finalReflection = mix(reflectionFade * reflectionFade, reflection, float(reflection != vec3(0.0)));

    #if MC_VERSION >= 11900
    finalReflection *= 1.0 - darknessFactor;
    #endif

    finalReflection *= 1.0 - blindFactor;

    return finalReflection;
}