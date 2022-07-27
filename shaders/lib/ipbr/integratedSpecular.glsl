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

#ifdef FSH
void getIntegratedSpecular(in vec4 albedo, in vec3 normal, in vec2 worldPos, in vec2 lightmap, inout float specular, inout float roughness) {
    float lAlbedo = length(albedo.rgb);

    if (mat > 299.9 && mat < 300.1) {// Sand
        specular = (float(albedo.b > 0.65) * 0.0625 + float(albedo.b > 0.75) * 0.125) * 0.125;
        roughness = 0.1;
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
    } else if (mat > 304.9 && mat < 305.1) {// Obsidian
        specular = (0.1 + lAlbedo * 0.1) * 0.5;
        roughness = 1.25;
    }

    #ifdef RAIN_PUDDLES
    float upNormal = dot(normal, upVec);

    specular += wetness * lightmap.y * (1.0 - lightmap.x) * (texture2D(noisetex, (worldPos + cameraPosition.xz) * 0.00125).r - 0.25) * 0.25 * clamp(upNormal, 0.0, 1.0);
    #endif

    specular = clamp(specular * SPECULAR_STRENGTH, 0.0, 0.95);
    roughness *= 0.01;
}
#endif

#ifdef VSH
void getIntegratedSpecularMaterials(inout float mat) {
    if (mc_Entity.x >= 300) mat = float(mc_Entity.x);
}
#endif