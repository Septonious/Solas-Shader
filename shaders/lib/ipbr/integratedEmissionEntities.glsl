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

void getIntegratedEmission(in vec3 albedo, inout vec2 lightmap, inout float emission){
    float lAlbedo = length(albedo);

    if (mat > 99.9 && mat < 100.1) { // Experience Orb
        emission = lAlbedo * 0.5;
    } else if (mat > 100.9 && mat < 101.1) { // Stray
        emission = float(lAlbedo > 0.999999999999999999 && albedo.r > 0.9019) * 0.25; // that was painful
    } else if (mat > 101.9 && mat < 102.1) { // Witch
        emission = float(albedo.g > 0.3 && albedo.r < 0.3);
    } else if (mat > 102.9 && mat < 103.1) { // Magma Cube
        emission = 0.75 + float(albedo.g > 0.5 && lAlbedo > 0.5) * 0.1;
        lightmap.x *= emission;
    } else if (mat > 103.9 && mat < 104.1) { // Drowned && Shulker
        emission = float(lAlbedo > 0.99) * 0.25;
    } else if (mat > 104.9 && mat < 105.1) { // JellySquid
        emission = 0.025 + float(lAlbedo > 0.99) * 0.25;
        lightmap.x *= emission;
    } else if (mat > 105.9 && mat < 106.1) { // End Crystal
        emission = float(albedo.r > 0.5 && albedo.g < 0.55);
        lightmap.x *= emission;
    }

    #ifdef PLAYER_BRIGHT_PARTS_HIGHLIGHT
    if (mat > 106.9 && mat < 107.1) {
        emission = float(pow32(pow32(lAlbedo)) > 0.99) * 0.125;
    }
    #endif

	emission *= EMISSION_STRENGTH;
}