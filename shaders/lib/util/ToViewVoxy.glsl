vec3 ToView(vec3 screenPos) {
    vec4 viewPos = vec4(screenPos, 1.0) * 2.0 - 1.0;
    viewPos = vxProjInv * viewPos;
    viewPos.xyz /= viewPos.w;

    return viewPos.xyz;
}