vec3 getReflection(vec3 viewPos, vec3 normal, vec3 color, float roughness) {
	vec3 reflectedViewPos = reflect(normalize(viewPos), normal) * 256.0;
	vec3 reflectedScreenPos = ToScreen(reflectedViewPos);
	vec3 reflection = vec3(0.0);

	#if REFLECTION_TYPE == 0
    bool outsideScreen = !(any(lessThan(reflectedScreenPos.xy, vec2(0.0))) || any(greaterThan(reflectedScreenPos.xy, vec2(1.0))));
	#elif REFLECTION_TYPE == 1
	bool outsideScreen = rayTrace(viewPos, reflectedViewPos, reflectedScreenPos);
	#endif

    if (outsideScreen) {
        reflection = texture2DLod(colortex6, reflectedScreenPos.xy, roughness).rgb;
		reflection = pow(reflection, vec3(2.2));
    }

    return mix(color, reflection, float(reflection != vec3(0.0)));
}