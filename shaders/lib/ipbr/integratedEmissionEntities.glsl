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
void getIntegratedEmission(in vec3 albedo, inout vec2 lightmap, inout float emission){
    float lAlbedo = length(albedo);

    if (mat > 99.9 && mat < 100.1) { // Experience Orb
        emission = 1.0;
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
        emission = float(albedo.r > 0.5 && albedo.g < 0.55) * 0.075;
        lightmap.x *= emission;
    }
    
    #ifdef ENTITY_BRIGHT_PARTS_HIGHLIGHT
    emission += float(lAlbedo > 0.85);
    #endif

	emission *= EMISSION_STRENGTH;
}
#endif


#ifdef VSH
void getIntegratedEmissionEntities(inout float mat){
    if (entityId == 100) mat = 100.0;
	if (entityId == 101) mat = 101.0;
	if (entityId == 102) mat = 102.0;
	if (entityId == 103) mat = 103.0;
	if (entityId == 104) mat = 104.0;
	if (entityId == 105) mat = 105.0;
	if (entityId == 106) mat = 106.0;
    if (entityId == 107) mat = 107.0;
	if (entityId == 108) mat = 108.0;
	if (entityId == 110) mat = 110.0;
	if (entityId == 111) mat = 111.0;
	if (entityId == 112) mat = 112.0;
	if (entityId == 113) mat = 113.0;
	if (entityId == 114) mat = 114.0;
	if (entityId == 115) mat = 115.0;
	if (entityId == 116) mat = 116.0;
	if (entityId == 117) mat = 117.0;
	if (entityId == 118) mat = 118.0;
	if (entityId == 119) mat = 119.0;
	if (entityId == 120) mat = 120.0;
}
#endif