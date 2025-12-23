vec3 ToNDC(vec3 screenPos) {
    vec4 iProjDiag = vec4(vxProjInv[0].x,
                        vxProjInv[1].y,
                        vxProjInv[2].zw);
    vec3 p3 = screenPos * 2.0 - 1.0;
    vec4 NDC = iProjDiag * p3.xyzz + vxProjInv[3];
    
    return NDC.xyz / NDC.w;
}