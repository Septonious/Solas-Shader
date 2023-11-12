void getIntegratedSpecular(inout vec4 albedo, in vec3 normal, in vec2 worldPos, in vec2 lightmap, in float emission, in float foliage, inout float specular) {
    float lAlbedo = length(albedo.rgb);

    if (mat == 300) {// Sand
        specular = pow7(albedo.b);
    } else if (mat == 301) {// Iron, Gold, Emerald, Diamond, Copper & Plates
        specular = clamp(pow4(lAlbedo) * 0.4, 0.06, 0.4);
    } else if (mat == 302) {// Polished & smooth blocks
        specular = clamp(pow6(lAlbedo) * 0.4, 0.06, 0.4);
    } else if (mat == 303) {//Dark blocks (deepslate)
        specular = lAlbedo * lAlbedo * 0.5;
    } else if (mat == 304) {//Near-black blocks (obsidian, blackstone)
        specular = clamp(lAlbedo * 0.35, 0.08, 0.5);
    } else if (mat == 305) {//Endstone
        specular = clamp(lAlbedo * lAlbedo * 0.1, 0.06, 0.15);
    } else if (mat == 306) {//Purpur
        specular = clamp(pow5(lAlbedo) * 0.4, 0.06, 0.5);
    } else if (mat == 307 || mat == 308) {//Prismarine
        specular = clamp(albedo.b * pow4(lAlbedo) * 0.5, 0.06, 0.3);
    } else if (mat == 309) {//Quartz & Calcite
        specular = clamp(pow16(lAlbedo) * 0.5, 0.06, 0.7);
    } else if (mat == 310) {// Wet farmland
        specular = float(lAlbedo < 0.3) * 0.1;
    } else if (mat == 311) {// Water cauldron
        if (albedo.b > 0.4 && lAlbedo > 0.5) {
            specular = 0.9;
            albedo.rgb = waterColor;
        }
    }

    #if defined RAIN_PUDDLES && defined GBUFFERS_TERRAIN
    if (specular == 0.0 && emission == 0.0 && foliage == 0.0) {
        float NoU = clamp(dot(normal, upVec), 0.0, 1.0);
        float puddles = wetness * pow8(lightmap.y) * texture2D(noisetex, (worldPos + cameraPosition.xz) * 0.00125).b * NoU * 0.125 * lAlbedo;
        specular += puddles;
    }
    #endif

    #ifdef TEST00
    specular = 0.95;
    #endif

    specular = clamp(specular * SPECULAR_STRENGTH, 0.0, 0.95);
}