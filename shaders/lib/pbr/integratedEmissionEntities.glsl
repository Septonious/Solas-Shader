void getIntegratedEmission(in vec3 albedo, inout vec2 lightmap, inout float emission){
    float lAlbedo = length(albedo);

    if (mat == 100) { // Experience Orb
        emission = lAlbedo * 6.0;
    } else if (mat == 101) { // Experience bottle
        emission = float(albedo.g > 0.4 && albedo.r < 0.4);
    } else if (mat == 102) { // Witch
        emission = float(albedo.g > 0.3 && albedo.r < 0.3);
    } else if (mat == 103) { // Magma Cube
        emission = 0.75 + float(albedo.g > 0.5 && lAlbedo > 0.5) * 0.1;
        lightmap.x *= emission;
    } else if (mat == 104) { // Drowned && Shulker
        emission = float(lAlbedo > 0.99) * 0.25;
    } else if (mat == 105) { // JellySquid
        emission = 0.025 + float(lAlbedo > 0.99) * 0.25;
        lightmap.x *= emission;
    } else if (mat == 106) { // End Crystal
        emission = float(albedo.r > 0.5 && albedo.g < 0.55) * 1.25;
        lightmap.x *= emission;
    } else if (mat == 107) { // Creaking
        emission = float(albedo.r > albedo.g + albedo.b) * 0.5;
    }
}