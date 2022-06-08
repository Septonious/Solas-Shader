vec3 ToScreen(in vec3 view) {
    vec4 temp = gbufferProjection * vec4(view, 1.0);
    temp.xyz /= temp.w;

    return temp.xyz * 0.5 + 0.5;
}

vec3 getReflection(vec3 viewPos, vec3 normal, float skyLightMap) {
	vec3 reflectedVector = reflect(normalize(viewPos), normal) * 64.0;
	vec3 reflectedScreenPos = ToScreen(viewPos + reflectedVector);
	vec3 reflectionFade = vec3(0.0);
	vec4 reflection = vec4(0.0);

	#if defined OVERWORLD
	vec3 nViewPos = normalize(viewPos.xyz + reflectedVector);
	float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
	float VoM = clamp(dot(nViewPos, -sunVec), 0.0, 1.0);
	float VoU = dot(nViewPos, upVec);

	reflectionFade = getAtmosphere(viewPos + reflectedVector);
	getSunMoon(reflectionFade, VoS, VoM, VoU, lightSun * 2.0, lightNight * 2.0);

	#if MC_VERSION >= 11900
	reflectionFade *= 1.0 - darknessFactor;
	#endif
	#elif defined NETHER
	reflectionFade = netherCol;
	#elif defined END
	reflectionFade = endCol;
	#endif

    bool outsideScreen = !(any(lessThan(reflectedScreenPos.xy, vec2(0.0))) || any(greaterThan(reflectedScreenPos.xy, vec2(1.0))));
    if (outsideScreen){
        reflection = texture2D(colortex5, reflectedScreenPos.xy);
    }

    return mix(reflectionFade * pow16(skyLightMap), reflection.rgb, pow(reflection.a, 0.1));
}