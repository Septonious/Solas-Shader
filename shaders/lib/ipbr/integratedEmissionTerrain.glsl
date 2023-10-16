void getIntegratedEmission(inout vec4 albedo, in vec3 viewPos, in vec3 worldPos, inout vec2 lightmap, inout float emission, inout float coloredLightingIntensity){
	float lAlbedo = clamp(length(albedo.rgb), 0.0, 1.0);

	#ifdef EMISSIVE_ORES
    if (mat == 100) { // Glowing Ores
		emission = clamp(max(max(max(albedo.r - albedo.b, albedo.r - albedo.g), max(albedo.b - albedo.g, albedo.b - albedo.r)), max(albedo.g - albedo.r, albedo.g - albedo.b)), 0.0, 1.0);
		emission = clamp(emission * int(emission > 0.1) * 16.0, 0.0, 1.0) * lAlbedo * 0.25;
    } else if (mat == 134) {
		emission = int(lAlbedo > 0.9) * 0.25;
	}
	#endif

	if (mat == 101) { // Crying Obsidian and Respawn Anchor
		emission = lAlbedo * lAlbedo * (1.0 + lightmap.x);
		coloredLightingIntensity = emission;
	} else if (mat == 102) { // Command Block
        vec3 comPos = fract(worldPos + cameraPosition);
             comPos = abs(comPos - vec3(0.5));

        float comPosM = min(max(comPos.x, comPos.y), min(max(comPos.x, comPos.z), max(comPos.y, comPos.z)));

        if (comPosM < 0.1882) { // Command Block Center
            vec3 dif = abs(vec3(albedo.r - albedo.b, albedo.r - albedo.g, albedo.b - albedo.g));
            emission = int(max(dif.r, max(dif.g, dif.b)) > 0.1);
            emission *= int(albedo.r > 0.44 || albedo.g > 0.29);
        }

	} else if (mat == 103) { // Nether Stems & Hyphae
        emission = int(albedo.r > 0.45 && albedo.b < 0.25) + int(albedo.b > 0.35 && albedo.r < 0.25 && albedo.b < 0.5);
	} else if (mat == 104) { // Glow Lichen
		emission = pow8(lAlbedo) * (1.0 - lightmap.y * 0.5) * 0.5;
		coloredLightingIntensity = emission;
	} else if (mat == 105) { // Redstone Things
		emission = int(albedo.r > 0.9);
	} else if (mat == 106) { // Soul Emissives
		emission = int(albedo.b > 0.5);
		coloredLightingIntensity = emission;
	} else if (mat == 107) { // Brewing Stand
		emission = int(albedo.r > 0.5 && albedo.b < 0.4);
	} else if (mat == 108) { // Glow berries
		emission = int(albedo.r > 0.5);
		coloredLightingIntensity = emission;
	} else if (mat == 109) { // Torch
		emission = int(lAlbedo > 0.9);
		coloredLightingIntensity = emission;
	} else if (mat == 110) { // Furnaces
		emission = int(albedo.r > 0.8 || (albedo.r > 0.6 && albedo.b < 0.5));
		coloredLightingIntensity = emission;
	} else if (mat == 111) { // Chorus
		emission = int(albedo.g > 0.45 && albedo.b < 0.8);
	} else if (mat == 112) { // Enchanting Table
		emission = int(albedo.b > 0.5) * 0.25;
		coloredLightingIntensity = emission;
	} else if (mat == 113) { // Normal Campfire && Magma Block
		emission = int(albedo.r > 0.65 && albedo.b < 0.35);
		coloredLightingIntensity = emission;
	} else if (mat == 114) { // Froglights
		emission = (1.5 - lAlbedo) * 0.5;
		coloredLightingIntensity = emission;
		albedo.rgb = pow3(albedo.rgb);
	} else if (mat == 115) { // Sculks
		emission = int(lAlbedo > 0.45 && albedo.r < 0.2) * 0.25;
	} else if (mat == 116) { // Redstone Lamp, Glowstone, Sea Lentern
		emission = min(lAlbedo * 2.0, 1.0) * 1.5;
		coloredLightingIntensity = emission;
	} else if (mat == 118) { // End Portal Frame
		emission = 16.0 * pow2(albedo.b - albedo.g) * int(albedo.r < 0.65);
		lightmap.x *= 0.5;
	} else if (mat == 119) {// End Rod
		emission = 0.05 * pow4(lAlbedo);
		coloredLightingIntensity = emission;
		albedo.rgb *= vec3(1.72, 1.12, 2.47);
	} else if (mat == 120) { // Powered Rail
		emission = int(albedo.g < 0.25);
	} else if (mat == 121 || mat == 122 || mat == 123) { // Fully emissive blocks
		emission = 0.5;
		coloredLightingIntensity = emission;
	}
	
	#ifdef EMISSIVE_POWDER_SNOW
	if (mat == 200){
		emission = 0.1;
	} 
	#endif

	#ifdef EMISSIVE_DEBRIS
	if (mat == 201) emission = 0.125;
	#endif

	#ifdef EMISSIVE_CONCRETE
	if (mat == 202) {
		emission = 1.0;
	}
	#endif

	#if defined OVERWORLD && defined EMISSIVE_FLOWERS
	if (mat >= 5 && mat <= 7) { // Flowers
		if (albedo.b > albedo.g || albedo.r > albedo.g) {
			emission = lAlbedo * (1.0 - wetness);
			emission *= 2.0 - clamp(length(viewPos) * 0.2, 0.0, 1.0);
			emission *= 1.0 - lightmap.y * 0.5;
			emission *= 0.125;
		}
	}
	#endif

	emission = clamp(emission * EMISSION_STRENGTH, 0.0, 8.0);
	coloredLightingIntensity = clamp(coloredLightingIntensity * 64.0 * int(lightmap.x > 0.25), 0.0, 0.98);
}