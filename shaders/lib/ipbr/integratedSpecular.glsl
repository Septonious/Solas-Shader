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

void getIntegratedSpecular(inout vec4 albedo, in vec3 normal, in vec2 worldPos, in vec2 lightmap, in float emission, in float foliage, inout float specular) {
    float lAlbedo = length(albedo.rgb);

    if (mat == 300) {// Sand
        specular = pow7(albedo.b);
    } else if (mat == 301) {// Iron Block
        specular = pow16(albedo.r) * 16.0;
    } else if (mat == 302) {// Gold Block & Gold Pressure Plate & Amethyst
        specular = pow8(clamp(lAlbedo, 0.0, 1.0));
    } else if (mat == 303) {// Emerald & Diamond Blocks
        specular = pow10(lAlbedo);
    } else if (mat == 304 || mat == 306) {// Polished Stones Blocks & Basalt & Prismarine (my previous shader really)
        specular = pow4(clamp(lAlbedo, 0.0, 1.0)) * 0.4;
    } else if (mat == 305) {// Obsidian & Polished Deepslate
        specular = pow(lAlbedo, 0.75) * 0.5;
    }// else {
        //if (foliage < 0.5 && emission < 0.5) {
            //specular = pow10(lAlbedo) * 0.1;
        //}
    //}

    #if defined RAIN_PUDDLES && defined GBUFFERS_TERRAIN
    if (specular == 0.0 && emission == 0.0 && foliage == 0.0) {
        float NoU = clamp(dot(normal, upVec), 0.0, 1.0);
        float puddles = wetness * pow8(lightmap.y) * (texture2D(noisetex, (worldPos + cameraPosition.xz) * 0.00125).b - 0.2) * NoU * 0.125;
        specular += puddles;
    }
    #endif

    specular = clamp(specular * SPECULAR_STRENGTH, 0.0, 0.95);
}