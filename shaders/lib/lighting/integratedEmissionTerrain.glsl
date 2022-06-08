#ifdef FSH
void getIntegratedEmission(inout float emissive, in vec2 lightmap, inout vec4 albedo, in vec3 worldPos){
	float newEmissive = 0.0;
	float lAlbedo = clamp(length(albedo.rgb), 0.0, 1.0);

	#ifdef EMISSIVE_ORES
    if (mat > 99.9 && mat < 100.1) { // Emissive Ores
        float stoneDif = max(abs(albedo.r - albedo.g), max(abs(albedo.r - albedo.b), abs(albedo.g - albedo.b)));
        float ore = max(max(stoneDif - 0.175, 0.0), 0.0);
        newEmissive = pow(ore, 0.25) * 0.125;
    } 
	#endif

	if (mat > 100.9 && mat < 101.1) { // Crying Obsidian and Respawn Anchor
		newEmissive = (albedo.b - albedo.r) * albedo.r;
        newEmissive *= newEmissive * 0.5;
	} else if (mat > 101.9 && mat < 102.1) { // Command Block
        vec3 comPos = fract(worldPos.xyz + cameraPosition.xyz);
             comPos = abs(comPos - vec3(0.5));

        float comPosM = min(max(comPos.x, comPos.y), min(max(comPos.x, comPos.z), max(comPos.y, comPos.z)));
        newEmissive = 0.0;

        if (comPosM < 0.1882) { // Command Block Center
            vec3 dif = vec3(albedo.r - albedo.b, albedo.r - albedo.g, albedo.b - albedo.g);
            dif = abs(dif);
            newEmissive = float(max(dif.r, max(dif.g, dif.b)) > 0.1);
            newEmissive *= float(albedo.r > 0.44 || albedo.g > 0.29);
        }

	} else if (mat > 102.9 && mat < 103.1) { // Warped Stem & Hyphae
		newEmissive = float(lAlbedo > 0.49) * 0.4 + float(lAlbedo > 0.59);
	} else if (mat > 103.9 && mat < 104.1) { // Crimson Stem & Hyphae
		newEmissive = (float(lAlbedo > 0.47) * 0.5 + float(lAlbedo > 0.50)) * float(albedo.b < 0.25);
	} else if (mat > 104.9 && mat < 105.1) { // Warped Nether Warts
		newEmissive = pow2(float(albedo.g - albedo.b));
	} else if (mat > 105.9 && mat < 106.1) { // Warped Nylium
		newEmissive = float(albedo.g > albedo.b && albedo.g > albedo.r) * pow(float(albedo.g - albedo.b), 3.0);
	} else if (mat > 107.9 && mat < 108.1) { // Amethyst
		newEmissive = float(lAlbedo > 0.5) * 0.1;
	} else if (mat > 109.9 && mat < 110.1) { // Glow Lichen
		newEmissive = (1.0 - lightmap.y) * (0.025 + float(albedo.r > albedo.g || albedo.r > albedo.b));
	} else if (mat > 110.9 && mat < 111.1) { // Redstone Things
		newEmissive = float(albedo.r > 0.75) * 0.1;
	} else if (mat > 111.9 && mat < 112.1) { // Soul Emissives
		newEmissive = float(lAlbedo > 0.9) * 0.1;
	} else if (mat > 112.9 && mat < 113.1) { // Brewing Stand
		newEmissive = float(albedo.r > 0.5 && albedo.b < 0.4) * 0.25;
	} else if (mat > 113.9 && mat < 114.1) { // Glow berries
		newEmissive = float(albedo.r > 0.5) * 0.5;
	} else if (mat > 114.9 && mat < 115.1) { // Torches
		newEmissive = float(lAlbedo > 0.99) * 0.1;
	} else if (mat > 115.9 && mat < 116.1) { // Furnaces
		newEmissive = float(albedo.r > 0.8 || (albedo.r > 0.6 && albedo.b < 0.5)) * 0.1;
	} else if (mat > 116.9 && mat < 117.1) { // Chorus
		newEmissive = float(albedo.r > albedo.b || albedo.r > albedo.g) * float(albedo.b > 0.575) * 0.25;
	} else if (mat > 117.9 && mat < 118.1) { // Enchanting Table
		newEmissive = float(lAlbedo > 0.75) * 0.1;
	} else if (mat > 118.9 && mat < 119.1) { // Soul Campfire
		newEmissive = float(albedo.b > albedo.r || albedo.b > albedo.g) * 0.25;
	} else if (mat > 119.9 && mat < 120.1) { // Normal Campfire
		newEmissive = float(albedo.r > 0.65 && albedo.b < 0.35) * 0.20;
	} else if (mat > 120.9 && mat < 121.9) { // Redstone Block
		newEmissive = 0.25 + lAlbedo * 0.25;
	} else if (mat > 121.9 && mat < 122.1) { // Glowstone, Fire, etc
		newEmissive = (1.0 + pow16(lAlbedo)) * 0.0625;
	} else if (mat > 122.9 && mat < 123.1) { // Sculks
		newEmissive = float(lAlbedo > 0.05 && albedo.r < 0.25) * 0.1;
	} else if (mat > 123.9 && mat < 124.1) { // Redstone Lamp
		newEmissive = 0.25 + float(lAlbedo > 0.75) * 0.25;
	} else if (mat > 124.9 && mat < 125.1) { // Sea Lantern
		newEmissive = float(lAlbedo > 0.95) * 0.25 + float(albedo.g > 0.4) * 0.025;
	} else if (mat > 125.9 && mat < 126.1) { // Nether Wart
		newEmissive = float(lAlbedo > 0.25) * 0.25 + float(lAlbedo > 0.75) * 0.5;
	}

	#ifdef POWDER_SNOW_HIGHLIGHT
	if (mat > 199.9 && mat < 200.1){
		newEmissive = 0.1;
	} 
	#endif

	#ifdef DEBRIS_HIGHLIGHT
	if (mat > 200.9 && mat < 201.1) newEmissive = 1.0;
	#endif

	#if defined OVERWORLD && defined EMISSIVE_FLOWERS
	if (isPlant > 0.9 && isPlant < 1.1){ // Flowers
		newEmissive = float(albedo.b > albedo.g || albedo.r > albedo.g) * 0.025 * (1.0 - rainStrength);
	}
	#endif

	emissive += newEmissive * EMISSION_STRENGTH;
}
#endif


#ifdef VSH
void getIntegratedEmissionMaterials(inout float mat, inout float isPlant){
	isPlant = 0.0;
	#ifdef EMISSIVE_ORES
	if (mc_Entity.x == 100) mat = 100.0;
	#endif
	if (mc_Entity.x == 101) mat = 101.0;
	if (mc_Entity.x == 102) mat = 102.0;
	if (mc_Entity.x == 103) mat = 103.0;
	if (mc_Entity.x == 104) mat = 104.0;
	if (mc_Entity.x == 105) mat = 105.0;
	if (mc_Entity.x == 106) mat = 106.0;
	if (mc_Entity.x == 108) mat = 108.0;
	if (mc_Entity.x == 110) mat = 110.0;
	if (mc_Entity.x == 111) mat = 111.0;
	if (mc_Entity.x == 112) mat = 112.0;
	if (mc_Entity.x == 113) mat = 113.0;
	if (mc_Entity.x == 114) mat = 114.0;
	if (mc_Entity.x == 115) mat = 115.0;
	if (mc_Entity.x == 116) mat = 116.0;
	if (mc_Entity.x == 117) mat = 117.0;
	if (mc_Entity.x == 118) mat = 118.0;
	if (mc_Entity.x == 119) mat = 119.0;
	if (mc_Entity.x == 120) mat = 120.0;
	if (mc_Entity.x == 121) mat = 121.0;
	if (mc_Entity.x == 122) mat = 122.0;
	if (mc_Entity.x == 123) mat = 123.0;
	if (mc_Entity.x == 124) mat = 124.0;
	if (mc_Entity.x == 125) mat = 125.0;
	if (mc_Entity.x == 126) mat = 126.0;
	if (mc_Entity.x == 127) mat = 127.0;

	#ifdef DEBRIS_HIGHLIGHT
	if (mc_Entity.x == 201) mat = 201.0;
	#endif

	#if defined EMISSIVE_FLOWERS && defined OVERWORLD
	if (mc_Entity.x == 5) isPlant = 1.0;
	#endif

	#ifdef POWDER_SNOW_HIGHLIGHT
	if (mc_Entity.x == 200) mat = 200;
	#endif
}
#endif