vec3 ToView(vec3 screenPos) {
    vec4 viewPos = gbufferProjectionInverse * (vec4(screenPos, 1.0) * 2.0 - 1.0);
         viewPos /= viewPos.w;
    return viewPos.xyz;
}