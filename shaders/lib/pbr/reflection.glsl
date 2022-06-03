vec3 ToScreen(in vec3 view) {
    vec4 temp = gbufferProjection * vec4(view, 1.0);
    temp.xyz /= temp.w;

    return temp.xyz * 0.5 + 0.5;
}

vec3 getReflection(vec3 viewPos, vec3 normal, vec3 reflectionFade) {
	vec3 reflectedVector = reflect(normalize(viewPos), normal) * 64.0;
	vec3 reflectedScreenPos = ToScreen(viewPos + reflectedVector);
	vec4 reflection = vec4(0.0);

    bool outsideScreen = !(any(lessThan(reflectedScreenPos.xy, vec2(0.0))) || any(greaterThan(reflectedScreenPos.xy, vec2(1.0))));
    if (outsideScreen){
        reflection = texture2D(colortex5, reflectedScreenPos.xy);
    }

    return mix(reflectionFade, reflection.rgb, reflection.a);
}