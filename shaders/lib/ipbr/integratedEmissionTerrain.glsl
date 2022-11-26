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

void getIntegratedEmission(inout vec4 albedo, in vec3 viewPos, in vec3 worldPos, inout vec2 lightmap, in float NoU, inout float emission){
	float lAlbedo = clamp(length(albedo.rgb), 0.0, 1.0);

	#ifdef EMISSIVE_ORES
    if (mat > 99.9 && mat < 100.1) { // Glowing Ores
		emission = clamp(max(max(max(albedo.r - albedo.b, albedo.r - albedo.g), max(albedo.b - albedo.g, albedo.b - albedo.r)), max(albedo.g - albedo.r, albedo.g - albedo.b)), 0.0, 1.0);
		emission = clamp(emission * int(emission > 0.1) * 8.0, 0.0, 1.0) * lAlbedo * 2.0;
    } 
	#endif

	if (mat > 100.9 && mat < 101.1) { // Crying Obsidian and Respawn Anchor
		emission = lAlbedo * lAlbedo * 4.0;
	} else if (mat > 101.9 && mat < 102.1) { // Command Block
        vec3 comPos = fract(worldPos + cameraPosition);
             comPos = abs(comPos - vec3(0.5));

        float comPosM = min(max(comPos.x, comPos.y), min(max(comPos.x, comPos.z), max(comPos.y, comPos.z)));

        if (comPosM < 0.1882) { // Command Block Center
            vec3 dif = vec3(albedo.r - albedo.b, albedo.r - albedo.g, albedo.b - albedo.g);
            dif = abs(dif);
            emission = int(max(dif.r, max(dif.g, dif.b)) > 0.1);
            emission *= int(albedo.r > 0.44 || albedo.g > 0.29);
        }

	} else if (mat > 102.9 && mat < 103.1) { // Nether Stems & Hyphae
        emission = lAlbedo * int(albedo.r < 0.1 || albedo.b < 0.2);
	} else if (mat > 103.9 && mat < 104.1) { // Glow Lichen
		emission = pow12(lAlbedo) * (1.0 - lightmap.y * 0.5) * 2.0;
	} else if (mat > 104.9 && mat < 105.1) { // Redstone Things
		emission = int(albedo.r > 0.9);
	} else if (mat > 105.9 && mat < 106.1) { // Soul Emissives
		emission = int(albedo.b > 0.5);
	} else if (mat > 106.9 && mat < 107.1) { // Brewing Stand
		emission = int(albedo.r > 0.5 && albedo.b < 0.4);
	} else if (mat > 107.9 && mat < 108.1) { // Glow berries
		emission = int(albedo.r > 0.5);
		albedo.rgb *= 1.0 + emission;
	} else if (mat > 108.9 && mat < 109.1) { // Torch
		emission = int(lAlbedo > 0.9);
	} else if (mat > 109.9 && mat < 110.1) { // Furnaces
		emission = int(albedo.r > 0.8 || (albedo.r > 0.6 && albedo.b < 0.5));
	} else if (mat > 110.9 && mat < 111.1) { // Chorus
		emission = pow3(albedo.g);
	} else if (mat > 111.9 && mat < 112.1) { // Enchanting Table
		emission = int(albedo.b > 0.5);
	} else if (mat > 112.9 && mat < 113.1) { // Normal Campfire && Magma Block
		emission = int(albedo.r > 0.65 && albedo.b < 0.35);
	} else if (mat > 113.9 && mat < 114.1) { // Froglights
		emission = 1.5 - lAlbedo;
		albedo.rgb = pow3(albedo.rgb) * 1.25;
	} else if (mat > 114.9 && mat < 115.1) { // Sculks
		emission = int(lAlbedo > 0.45 && albedo.r < 0.2) * 0.25;
	} else if (mat > 115.9 && mat < 116.1) { // Redstone Lamp, Glowstone, Sea Lentern
		emission = min(lAlbedo * 2.0, 1.0) * 2.0;
	} else if (mat > 117.9 && mat < 118.1) { // End Portal Frame
		emission = 16.0 * pow2(albedo.b - albedo.g) * int(albedo.r < 0.65);
		lightmap.x *= 0.5;
	} else if (mat > 118.9 && mat < 119.1) {// End Rod
		emission = 0.125 * pow4(lAlbedo);
		albedo.rgb *= vec3(1.15, 0.75, 1.65) * 1.5;
	} else if (mat > 119.9 && mat < 120.1) { // Powered Rail
		emission = 0.25 * int(albedo.g < 0.25);
	} else if ((mat > 120.9 && mat < 121.1) || (mat > 121.9 && mat < 122.1) || (mat > 122.9 && mat < 123.1)) { // Fully emissive blocks
		emission = lAlbedo * 2.0;
	}

	#ifdef EMISSIVE_CONCRETE
	if (mat > 201.9 && mat < 202.1) {
		emission = 1.0;
	}
	#endif

	#ifdef EMISSIVE_POWDER_SNOW
	if (mat > 199.9 && mat < 200.1){
		emission = 0.1;
	} 
	#endif

	#ifdef EMISSIVE_DEBRIS
	if (mat > 200.9 && mat < 201.1) emission = 0.125;
	#endif

	#if defined OVERWORLD && defined EMISSIVE_FLOWERS
	if (isPlant > 0.9 && isPlant < 1.1 || mat > 132.9 && mat < 133.1){ // Flowers
		if (albedo.b > albedo.g || albedo.r > albedo.g) {
			emission = 0.5 * lAlbedo * (1.0 - rainStrength);
			emission *= 2.0 - clamp(length(viewPos) * 0.2, 0.0, 1.0);
			emission *= 0.5 + clamp(sin(frameTimeCounter) * cos(frameTimeCounter * 0.5), 0.0, 0.5);
		}
	}
	#endif

	emission = clamp(emission, 0.0, 2.0);
}