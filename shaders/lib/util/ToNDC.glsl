#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)

vec3 ToNDC(vec3 screenPos) {
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x,
						  gbufferProjectionInverse[1].y,
						  gbufferProjectionInverse[2].zw);
    vec3 p3 = screenPos * 2.0 - 1.0;
    vec4 NDC = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return NDC.xyz / NDC.w;
}