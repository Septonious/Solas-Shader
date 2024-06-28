vec3 ToNDC(vec3 screenPos) {
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x,
						  gbufferProjectionInverse[1].y,
						  gbufferProjectionInverse[2].zw);
    vec3 p3 = screenPos * 2.0 - 1.0;
    vec4 NDC = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    
    return NDC.xyz / NDC.w;
}