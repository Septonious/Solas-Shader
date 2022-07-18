vec3 ToScreen(in vec3 view) {
    vec4 temp = gbufferProjection * vec4(view, 1.0);
    temp.xyz /= temp.w;

    return temp.xyz * 0.5 + 0.5;
}