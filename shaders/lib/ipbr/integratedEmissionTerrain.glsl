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

void getIntegratedEmission(inout vec4 albedo, in vec3 viewPos, in vec3 worldPos, inout vec2 lightmap, inout float emission){
	float lAlbedo = clamp(length(albedo.rgb), 0.0, 1.0);

	#ifdef EMISSIVE_ORES
    if (mat > 99.9 && mat < 100.1) { // Glowing Ores
        emission = max(abs(albedo.r - albedo.g), max(abs(albedo.r - albedo.b), abs(albedo.g - albedo.b)));
		emission = pow2(emission) * 2.0;
    } 
	#endif

	if (mat > 100.9 && mat < 101.1) { // Crying Obsidian and Respawn Anchor
		emission = lAlbedo * 4.0;
	} else if (mat > 101.9 && mat < 102.1) { // Command Block
        vec3 comPos = fract(worldPos + cameraPosition);
             comPos = abs(comPos - vec3(0.5));

        float comPosM = min(max(comPos.x, comPos.y), min(max(comPos.x, comPos.z), max(comPos.y, comPos.z)));

        if (comPosM < 0.1882) { // Command Block Center
            vec3 dif = vec3(albedo.r - albedo.b, albedo.r - albedo.g, albedo.b - albedo.g);
            dif = abs(dif);
            emission = float(max(dif.r, max(dif.g, dif.b)) > 0.1);
            emission *= float(albedo.r > 0.44 || albedo.g > 0.29);
        }

	} else if (mat > 102.9 && mat < 103.1) { // Warped Stem & Hyphae
        emission = float(lAlbedo > 0.5);
	} else if (mat > 103.9 && mat < 104.1) { // Crimson Stem & Hyphae
		emission = float(lAlbedo > 0.48 && albedo.b < 0.25);
	} else if (mat > 104.9 && mat < 105.1) { // Warped Nether Warts
		emission = float(lAlbedo > 0.75) * 0.025;
	} else if (mat > 105.9 && mat < 106.1) { // Warped Nylium
		emission = float(albedo.g > albedo.b && albedo.g > albedo.r) * pow3(float(albedo.g - albedo.b));
	} else if (mat > 107.9 && mat < 108.1) { // Amethyst
		emission = pow5(lAlbedo) * 0.5;
	} else if (mat > 109.9 && mat < 110.1) { // Glow Lichen
		emission = (0.005 + pow16(lAlbedo)) * (1.0 - lightmap.y * 0.5) * 2.0;
	} else if (mat > 110.9 && mat < 111.1) { // Redstone Things
		emission = float(albedo.r > 0.9) * 0.5;
	} else if (mat > 111.9 && mat < 112.1) { // Soul Emissives
		emission = float(lAlbedo > 0.9);
	} else if (mat > 112.9 && mat < 113.1) { // Brewing Stand
		emission = float(albedo.r > 0.5 && albedo.b < 0.4);
	} else if (mat > 113.9 && mat < 114.1) { // Glow berries
		emission = float(albedo.r > 0.5) * 0.5;
		albedo.rgb *= 1.0 + float(albedo.r > 0.5);
	} else if (mat > 114.9 && mat < 115.1) { // Torch & Shroomlight
		emission = 0.15 + float(lAlbedo > 0.99) * 0.5;
	} else if (mat > 115.9 && mat < 116.1) { // Furnaces
		emission = float(albedo.r > 0.8 || (albedo.r > 0.6 && albedo.b < 0.5));
	} else if (mat > 116.9 && mat < 117.1) { // Chorus
		emission = float(albedo.g > 0.55) * 0.5;
	} else if (mat > 117.9 && mat < 118.1) { // Enchanting Table
		emission = float(lAlbedo > 0.75);
	} else if (mat > 118.9 && mat < 119.1) { // Soul Campfire
		emission = float(albedo.b > albedo.r || albedo.b > albedo.g) * 1.5;
	} else if (mat > 119.9 && mat < 120.1) { // Normal Campfire && Magma Block
		emission = float(albedo.r > 0.65 && albedo.b < 0.35) * 2.0;
	} else if (mat > 120.9 && mat < 121.9) { // Redstone Block && Lava
		emission = 0.2 + pow2(lAlbedo) * 0.8;
	} else if (mat > 121.9 && mat < 122.1) { // Froglights
		emission = (1.0 - clamp(length(pow4(albedo.rgb)), 0.0, 0.99)) * 16.0;
		albedo.rgb = pow3(albedo.rgb);
	} else if (mat > 122.9 && mat < 123.1) { // Sculks
		emission = float(lAlbedo > 0.05 && albedo.r < 0.25);
	} else if (mat > 123.9 && mat < 124.1) { // Redstone Lamp, Glowstone
		emission = 1.0 + pow24(lAlbedo);
	} else if (mat > 124.9 && mat < 125.1) { // Sea Lantern
		emission = pow10(lAlbedo);
	} else if (mat > 125.9 && mat < 126.1) { // Nether Wart
		emission = float(lAlbedo > 0.25) * 0.2 + float(lAlbedo > 0.75) * 0.2;
	} else if (mat > 126.9 && mat < 127.1) { // End Portal Frame
		emission = pow2(albedo.b - albedo.g) * 16.0 * float(albedo.r < 0.65);
		lightmap.x *= 0.5;
	} else if (mat > 127.9 && mat < 128.1) { // Dragon Egg
		emission = lAlbedo * lAlbedo * 4.0;
	} else if (mat > 128.9 && mat < 129.1) {// End Rod
		emission = pow4(lAlbedo) * 0.125;
		albedo.rgb *= vec3(1.15, 0.75, 1.65) * 1.5;
	} else if (mat > 129.9 && mat < 130.1) { // Powered Rail
		emission = float(albedo.r > 0.5 && albedo.g < 0.25) * 0.125;
	} else if (mat > 130.9 && mat < 131.1) { // Fire
		emission = 0.5;
	} else if (mat > 131.9 && mat < 132.1) { // Normal Lantern
		emission = float(albedo.r > 0.6);
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
	if (isPlant > 0.9 && isPlant < 1.1){ // Flowers
		if (albedo.b > albedo.g || albedo.r > albedo.g) {
			emission = 0.2 * lAlbedo * (1.0 - rainStrength);
			emission *= 2.0 - clamp(length(viewPos) * 0.2, 0.0, 1.0);
			emission *= 0.5 + clamp(sin(frameTimeCounter) * cos(frameTimeCounter * 0.5), 0.0, 0.5);
		}
	}
	#endif
}