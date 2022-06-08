#ifdef FSH
void getIntegratedSpecular(inout float specular, in vec2 worldPos, in vec2 lightmap, in vec4 albedo) {
    float lAlbedo = length(albedo.rgb);

    if (mat > 299.9 && mat < 300.1) specular = float(albedo.b > 0.65) * 0.03125 + float(albedo.b > 0.75) * 0.125; // Sand
    if (mat > 300.9 && mat < 301.1) specular = float(pow24(albedo.r)) * 0.75; // Iron Block
    if (mat > 301.9 && mat < 302.1) specular = pow8(lAlbedo * 0.55); // Gold & Diamond & Emerald Blocks
    if (mat > 302.9 && mat < 303.1) specular = max(0.25 - pow24(lAlbedo), 0.0) * 0.25; // Polished Stones Blocks
    if (mat > 303.9 && mat < 304.1) specular = lAlbedo * 0.25;

    #ifdef RAIN_PUDDLES
    specular += wetness * lightmap.y * (1.0 - lightmap.x) * (texture2D(noisetex, (worldPos + cameraPosition.xz) * 0.0025).r - 0.5);
    #endif

    specular *= SPECULAR_STRENGTH;
}
#endif

#ifdef VSH
void getIntegratedSpecularMaterials(inout float mat) {
    if (mc_Entity.x == 300) mat = 300.0;
    if (mc_Entity.x == 301) mat = 301.0;
    if (mc_Entity.x == 302) mat = 302.0;
    if (mc_Entity.x == 303) mat = 303.0;
    if (mc_Entity.x == 304) mat = 304.0;
}
#endif