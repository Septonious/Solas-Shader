/*
no switches?
⠀⣞⢽⢪⢣⢣⢣⢫⡺⡵⣝⡮⣗⢷⢽⢽⢽⣮⡷⡽⣜⣜⢮⢺⣜⢷⢽⢝⡽⣝
 ⠸⡸⠜⠕⠕⠁⢁⢇⢏⢽⢺⣪⡳⡝⣎⣏⢯⢞⡿⣟⣷⣳⢯⡷⣽⢽⢯⣳⣫⠇ 
⠀⠀⢀⢀⢄⢬⢪⡪⡎⣆⡈⠚⠜⠕⠇⠗⠝⢕⢯⢫⣞⣯⣿⣻⡽⣏⢗⣗⠏⠀
 ⠀⠪⡪⡪⣪⢪⢺⢸⢢⢓⢆⢤⢀⠀⠀⠀⠀⠈⢊⢞⡾⣿⡯⣏⢮⠷⠁⠀⠀
 ⠀⠀⠀⠈⠊⠆⡃⠕⢕⢇⢇⢇⢇⢇⢏⢎⢎⢆⢄⠀⢑⣽⣿⢝⠲⠉⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⡿⠂⠠⠀⡇⢇⠕⢈⣀⠀⠁⠡⠣⡣⡫⣂⣿⠯⢪⠰⠂⠀⠀⠀⠀
 ⠀⠀⠀⠀⡦⡙⡂⢀⢤⢣⠣⡈⣾⡃⠠⠄⠀⡄⢱⣌⣶⢏⢊⠂⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⢝⡲⣜⡮⡏⢎⢌⢂⠙⠢⠐⢀⢘⢵⣽⣿⡿⠁⠁⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠨⣺⡺⡕⡕⡱⡑⡆⡕⡅⡕⡜⡼⢽⡻⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⣼⣳⣫⣾⣵⣗⡵⡱⡡⢣⢑⢕⢜⢕⡝⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⣴⣿⣾⣿⣿⣿⡿⡽⡑⢌⠪⡢⡣⣣⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⡟⡾⣿⢿⢿⢵⣽⣾⣼⣘⢸⢸⣞⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠁⠇⠡⠩⡫⢿⣝⡻⡮⣒⢽⠋
*/

void getIntegratedSpecular(in vec4 albedo, in vec3 normal, in vec2 worldPos, in vec2 lightmap, inout float specular, inout float roughness) {
    float lAlbedo = length(albedo.rgb);

    if (mat > 299.9 && mat < 300.1) {// Sand
        specular = (float(albedo.b > 0.65) * 0.125 + float(albedo.b > 0.75));
        roughness = 0.15;
    } else if (mat > 300.9 && mat < 301.1) {// Iron Block
        specular = float(pow16(albedo.r)) * 8.0;
        roughness = 0.5;
    } else if (mat > 301.9 && mat < 302.1) {// Gold Block & Gold Pressure Plate
        specular = pow10(lAlbedo);
        roughness = 0.25;
    } else if (mat > 302.9 && mat < 303.1) {// Emerald & Diamond Blocks
        specular = pow12(lAlbedo);
        roughness = 0.25;
    } else if (mat > 303.9 && mat < 304.1) {// Polished Stones Blocks & Basalt
        specular = pow2(lAlbedo) * 0.175;
        roughness = 1.75;
    } else if (mat > 304.9 && mat < 305.1) {// Obsidian & Polished Deepslate
        specular = (0.1 + lAlbedo * 0.1) * 0.25;
        roughness = 1.25;
    } else if (mat > 305.9 && mat < 306.1) { // Grass Block & Dirt Path
        specular = 1.0;
        roughness = 0.0;
    }

    #if defined RAIN_PUDDLES && defined GBUFFERS_TERRAIN
    float upNormal = clamp(dot(normal, upVec), 0.0, 0.75);
    float puddles = wetness * pow16(lightmap.y) * (1.0 - lightmap.x) * texture2D(noisetex, (worldPos + cameraPosition.xz) * 0.00125).b * upNormal;

    if (puddles > 0.0) {
        specular += puddles;
        roughness = mix(puddles, roughness, roughness);
    }
    #endif

    specular = clamp(specular * SPECULAR_STRENGTH, 0.0, 0.99);
    roughness *= 0.01;
}