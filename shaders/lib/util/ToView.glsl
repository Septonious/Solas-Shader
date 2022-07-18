vec3 ToView(vec3 screen) {
    vec4 clip = vec4(screen, 1.0) * 2.0 - 1.0;
    clip = gbufferProjectionInverse * clip;
    clip.xyz /= clip.w;

    return clip.xyz;
}