vec3 ToScreen(vec3 viewPos) {
    vec4 screenPos = gbufferProjection * vec4(viewPos, 1.0);
    screenPos.xyz /= screenPos.w;

    return screenPos.xyz * 0.5 + 0.5;
}