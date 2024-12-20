vec3 ToView(vec3 pos) {
    vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x,
                          gbufferProjectionInverse[1].y,
                          gbufferProjectionInverse[2].zw);
    vec3 smoothPos = pos * 2.0 - 1.0;
    vec4 viewPos = iProjDiag * smoothPos.xyzz + gbufferProjectionInverse[3];

    return viewPos.xyz / viewPos.w;
}