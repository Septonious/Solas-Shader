vec3 getBlocklightColor(int id) {
	vec3 color = vec3(0.0);

	//Glow Lichen, Sea Pickle
	if (id == 3) color = vec3(GLSP_R, GLSP_G, GLSP_B) * GLSP_I;
	//Brewing Stand
	else if(id == 4) color = vec3(BS_R, BS_G, BS_B) * BS_I;
	//Torch, Lantern, Campfire, Fire
	else if(id == 5 || id == 15) {
		vec3 fireAnimation = vec3(1.0 - cos(sin(frameTimeCounter * 3.0) * 5.0 + frameTimeCounter) * 0.1);
		color = pow(vec3(TLCF_R, TLCF_G, TLCF_B), fireAnimation) * TLCF_I;
	}
	//Soul Torch, Soul Lantern, Soul Campfire, Soul Fire
	else if(id == 6 || id == 16) {
		vec3 fireAnimation = vec3(1.0 - cos(sin(frameTimeCounter * 2.0) * 4.0 + frameTimeCounter * 1.25) * 0.15);
		color = pow(vec3(SOUL_R, SOUL_G, SOUL_B), fireAnimation) * SOUL_I;
	}
	//End Rod
	else if(id == 7) color = vec3(ER_R, ER_G, ER_B) * ER_I;
	//Sea Lantern
	else if(id == 8) color = vec3(SL_R, SL_G, SL_B) * SL_I;
	//Glowstone
	else if(id == 9) color = vec3(GS_R, GS_G, GS_B) * GS_I;
	//Shroomlight, Redstone Lamp, Copper Bulbs
	else if(id == 10) color = vec3(SLRL_R, SLRL_G, SLRL_B) * SLRL_I;
	//Respawn Anchor, Crying Obsidian
	else if(id == 11) color = vec3(RACO_R, RACO_G, RACO_B) * RACO_I;
	//Lava
	else if(id == 12) color = vec3(LAVA_R, LAVA_G, LAVA_B + 0.02) * LAVA_I;
	//Cave Berries
	else if(id == 13) color = vec3(CB_R, CB_G, CB_B) * CB_I;
	//Amethyst
	else if(id == 14) color = vec3(AM_R, AM_G, AM_B) * AM_I;
	//Magma Block
	else if(id == 21) color = vec3(MB_R, MB_G, MB_B) * MB_I;

	#ifdef EMISSIVE_ORES
	#ifdef EMISSIVE_EMERALD_ORE
    //Emerald Ore
    else if(id == 22) color = normalize(vec3(0.05, 1.00, 0.15)) * 0.25;
	#endif
	#ifdef EMISSIVE_DIAMOND_ORE
    //Diamond Ore
    else if(id == 23) color = normalize(vec3(0.10, 0.40, 1.00)) * 0.25;
	#endif
	#ifdef EMISSIVE_COPPER_ORE
    //Copper Ore
    else if(id == 24) color = normalize(vec3(0.60, 0.70, 0.30)) * 0.25;
	#endif
	#ifdef EMISSIVE_LAPIS_ORE
    //Lapis Ore
    else if(id == 25) color = normalize(vec3(0.00, 0.10, 1.20)) * 0.25;
	#endif
	#ifdef EMISSIVE_GOLD_ORE
    //Gold Ore
    else if(id == 26) color = normalize(vec3(1.00, 0.75, 0.10)) * 0.25;
	#endif
	#ifdef EMISSIVE_IRON_ORE
    //Iron Ore
    else if(id == 27) color = normalize(vec3(0.70, 0.40, 0.30)) * 0.25;
	#endif
	#ifdef EMISSIVE_REDSTONE_ORE
    //Redstone Ore
    else if(id == 28) color = normalize(vec3(1.00, 0.05, 0.00)) * 0.25;
	#endif
	#endif

    //Lit Redstone Ore & Redstone Torch
    else if(id == 29) color = vec3(1.00, 0.05, 0.00);
    //Powered Rails & Shot Target
    else if(id == 30) color = vec3(1.00, 0.05, 0.00) * 0.5;
    //Nether Portal
    else if(id == 31) color = vec3(NP_R, NP_G, NP_B) * NP_I;
    //Orchre Froglight
    else if(id == 32) color = vec3(OF_R, OF_G, OF_B) * OF_I;
    //Verdant Froglight
    else if(id == 33) color = vec3(VF_R, VF_G, VF_B) * VF_I;
    //Pearlescent Froglight
    else if(id == 34) color = vec3(PF_R, PF_G, PF_B) * PF_I;

	#ifdef EMISSIVE_FLOWERS
    //Red flowers
    else if(id == 35 || id == 309 || id == 310) color = normalize(vec3(1.00, 0.05, 0.05)) * 0.20;
    //Pink flowers
    else if(id == 36 || id == 305 || id == 306 || id == 311 || id == 312) color = normalize(vec3(0.80, 0.20, 0.60)) * 0.40;
    //Yellow flowers
    else if(id == 37 || id == 307 || id == 308) color = normalize(vec3(0.80, 0.50, 0.05)) * 0.20;
    //Blue flowers
    else if(id == 38) color = normalize(vec3(0.00, 0.15, 1.00)) * 0.20;
    //White flowers
    else if(id == 39) color = normalize(vec3(0.80, 0.80, 0.80)) * 0.20;
    //Orange flowers
    else if(id == 40) color = normalize(vec3(1.00, 0.70, 0.05)) * 0.20;
	#endif

	//Jack-O-Lantern
	else if(id == 41) color = vec3(JL_R, JL_G, JL_B) * JL_I;
    //Enchanting table
    else if(id == 42) color = vec3(ET_R, ET_G, ET_B) * ET_I;
	//Red Candle
	else if(id == 43) color = normalize(vec3(1.0, 0.1, 0.1));
	//Orange Candle
	else if(id == 44) color = normalize(vec3(1.0, 0.5, 0.1));
	//Yellow Candle
	else if(id == 45) color = normalize(vec3(1.0, 1.0, 0.1));
	//Brown Candle
	else if(id == 46) color = normalize(vec3(0.7, 0.7, 0.0));
	//Green Candle
	else if(id == 47) color = normalize(vec3(0.1, 1.0, 0.1));
	//Lime Candle
	else if(id == 48) color = normalize(vec3(0.0, 1.0, 0.1));
	//Blue Candle
	else if(id == 49) color = normalize(vec3(0.1, 0.1, 1.0));
	//Light blue Candle
	else if(id == 50) color = normalize(vec3(0.5, 0.5, 1.0));
	//Cyan Candle
	else if(id == 51) color = normalize(vec3(0.1, 1.0, 1.0));
	//Purple Candle
	else if(id == 52) color = normalize(vec3(0.7, 0.1, 1.0));
	//Magenta Candle
	else if(id == 53) color = normalize(vec3(1.0, 0.1, 1.0));
	//Pink Candle
	else if(id == 54) color = normalize(vec3(1.0, 0.5, 1.0));
	//Black Candle
	else if(id == 55) color = normalize(vec3(0.3, 0.3, 0.3));
	//White Candle
	else if(id == 56) color = normalize(vec3(0.9, 0.9, 0.9));
	//Gray Candle
	else if(id == 57) color = normalize(vec3(0.5, 0.5, 0.5));
	//Light gray Candle
	else if(id == 58) color = normalize(vec3(0.7, 0.7, 0.7));
    //Candle
    else if(id == 59) color = normalize(vec3(0.6, 0.5, 0.4));
    //Beacon
    else if(id == 60) color = vec3(BC_R, BC_G, BC_B) * BC_I;
	//Sculk Sensor
	else if(id == 62) color = vec3(0.20, 0.55, 1.00) * 2.5;
	//Calibrated Sculk Sensor
	else if(id == 63) color = vec3(1.00, 0.25, 0.75) * 2.5;
	//Fungi
	else if(id == 64) color = vec3(1.0, 0.2, 0.1) * 0.1;
	//Crimson Stem & Hyphae
	else if(id == 65) color = vec3(1.0, 0.2, 0.1) * 0.2;
	//Warped Stem & Hyphae
	else if(id == 66) color = vec3(0.1, 0.5, 0.7) * 0.2;
	//Mob Spawner
	else if(id == 69) color = vec3(0.1, 0.01, 0.15);
	//End Portal With Eye
	else if(id == 71) color = vec3(EP_R, EP_G, EP_B) * EP_I;
	//Zinc Ore
	else if(id == 72) color = vec3(0.4);
	//Creaking Heart (Active)
	else if(id == 73) color = vec3(1.0, 0.3, 0.1);

	#ifdef EMISSIVE_FLOWERS
    //Red Potted flowers
    else if(id == 74) color = normalize(vec3(1.00, 0.05, 0.05)) * 0.20;
    //Pink Potted flowers
    else if(id == 75) color = normalize(vec3(0.80, 0.20, 0.60)) * 0.20;
    //Yellow Potted flowers
    else if(id == 76) color = normalize(vec3(0.80, 0.50, 0.05)) * 0.20;
    //Blue Potted flowers
    else if(id == 77) color = normalize(vec3(0.00, 0.15, 1.00)) * 0.20;
    //White Potted flowers
    else if(id == 78) color = normalize(vec3(0.80, 0.80, 0.80)) * 0.20;
    //Orange Potted flowers
    else if(id == 79) color = normalize(vec3(1.00, 0.70, 0.05)) * 0.20;
	#endif

    //Chorus
    else if(id == 80) color = vec3(0.12, 0.1, 0.1);

	//Crimson Fungus
	else if(id == 81) color = vec3(1.1, 0.3, 0.1);

	//Warped Fungus
	else if(id == 82) color = vec3(0.3, 0.6, 0.9) * 0.5;

	//Copper Torches, Lanterns, Etc
	else if(id == 83 || id == 84) color = vec3(0.1, 0.7, 0.2) * 0.5;

	//Generic emitters with different colors
	//Blocks in this range will emit their respective color
	//A good way to quickly make modded blocks emit light
	else if(id == 194) color = normalize(vec3(1.00, 0.05, 0.05)) * 0.50; //block.10194, red
	else if(id == 195) color = normalize(vec3(1.00, 0.70, 0.05)) * 0.50; //block.10195, orange
	else if(id == 196) color = normalize(vec3(0.80, 0.50, 0.05)) * 0.50; //block.10196, yellow
	else if(id == 197) color = normalize(vec3(0.10, 1.00, 0.10)) * 0.50; //block.10197, green
	else if(id == 198) color = normalize(vec3(0.00, 0.15, 1.00)) * 0.50; //block.10198, blue
	else if(id == 199) color = normalize(vec3(0.70, 0.10, 1.00)) * 0.50; //block.10199, purple
	else if(id == 200) color = normalize(vec3(0.80, 0.80, 0.80)) * 0.50; //block.10200, white

	return color;
}

const vec3[] blocklightTintArray = vec3[](
	//Red
	vec3(1.0, 0.1, 0.1),
	//Orange
	vec3(1.0, 0.5, 0.1),
	//Yellow
	vec3(1.0, 1.0, 0.1),
	//Brown
	vec3(0.7, 0.7, 0.0),
	//Green
	vec3(0.1, 1.0, 0.1),
	//Lime
	vec3(0.1, 1.0, 0.5),
	//Blue
	vec3(0.1, 0.1, 1.0),
	//Light blue
	vec3(0.5, 0.5, 1.0),
	//Cyan
	vec3(0.1, 1.0, 1.0),
	//Purple
	vec3(0.7, 0.1, 1.0),
	//Magenta
	vec3(1.0, 0.1, 1.0),
	//Pink
	vec3(1.0, 0.5, 1.0),
	//Black
	vec3(0.1, 0.1, 0.1),
	//White
	vec3(0.9, 0.9, 0.9),
	//Gray
	vec3(0.3, 0.3, 0.3),
	//Light gray
	vec3(0.7, 0.7, 0.7),
	//Buffer
	vec3(0.0)
);