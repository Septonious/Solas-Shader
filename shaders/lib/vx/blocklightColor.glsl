vec3 getBlocklightColor(in int id) {
	vec3 color = vec3(0.0);

	//Glow Lichen, Sea Pickle
	if (id == 3) color = vec3(GLSP_R, GLSP_G, GLSP_B) * GLSP_I;
	//Brewing Stand
	if (id == 4) color = vec3(BS_R, BS_G, BS_B) * BS_I;
	//Torch, Lantern, Campfire, Fire
	if (id == 5) color = vec3(TLCF_R, TLCF_G, TLCF_B) * TLCF_I;
	//Soul Torch, Soul Lantern, Soul Campfire, Soul Fire
	if (id == 6) color = vec3(SOUL_R, SOUL_G, SOUL_B) * SOUL_I;
	//End Rod
	if (id == 7) color = vec3(ER_R, ER_G, ER_B) * ER_I;
	//Sea Lantern
	if (id == 8) color = vec3(SL_R, SL_G, SL_B) * SL_I;
	//Glowstone
	if (id == 9) color = vec3(GS_R, GS_G, GS_B) * GS_I;
	//Shroomlight, Redstone Lamp, Copper Bulbs
	if (id == 10) color = vec3(SLRL_R, SLRL_G, SLRL_B) * SLRL_I;
	//Respawn Anchor, Crying Obsidian
	if (id == 11) color = vec3(RACO_R, RACO_G, RACO_B) * RACO_I;
	//Lava
	if (id == 12) color = vec3(LAVA_R, LAVA_G, LAVA_B + 0.02) * LAVA_I;
	//Cave Berries
	if (id == 13) color = vec3(CB_R, CB_G, CB_B) * CB_I;
	//Amethyst
	if (id == 14) color = vec3(METH_lmao_R, METH_lmao_G, METH_lmao_B) * METH_lmao_I;
	//Magma Block
	if (id == 21) color = vec3(MB_R, MB_G, MB_B) * MB_I;

	#ifdef EMISSIVE_ORES
    //Emerald Ore
    if (id == 22) color = normalize(vec3(0.05, 1.00, 0.15)) * 0.15;
    //Diamond Ore
    if (id == 23) color = normalize(vec3(0.10, 0.40, 1.00)) * 0.15;
    //Copper Ore
    if (id == 24) color = normalize(vec3(0.60, 0.70, 0.30)) * 0.15;
    //Lapis Ore
    if (id == 25) color = normalize(vec3(0.00, 0.10, 1.20)) * 0.15;
    //Gold Ore
    if (id == 26) color = normalize(vec3(1.00, 0.75, 0.10)) * 0.15;
    //Iron Ore
    if (id == 27) color = normalize(vec3(0.70, 0.40, 0.30)) * 0.15;
    //Redstone Ore
    if (id == 28) color = normalize(vec3(1.00, 0.05, 0.00)) * 0.15;
	#endif

    //Lit Redstone Ore
    if (id == 29) color = vec3(1.00, 0.05, 0.00);
    //Powered Rails
    if (id == 30) color = vec3(1.00, 0.05, 0.00);
    //Nether Portal
    if (id == 31) color = vec3(NP_R, NP_G, NP_B) * NP_I;
    //Orchre Froglight
    if (id == 32) color = normalize(vec3(1.00, 0.55, 0.25)) * 4.0;
    //Verdant Froglight
    if (id == 33) color = normalize(vec3(0.0, 1.00, 0.05)) * 4.0;
    //Pearlescent Froglight
    if (id == 34) color = normalize(vec3(1.00, 0.20, 0.90)) * 4.0;

	#ifdef EMISSIVE_FLOWERS
    //Red Potted flowers
    if (id == 35) color = normalize(vec3(1.00, 0.05, 0.05)) * 0.20;
    //Pink Potted flowers
    if (id == 36) color = normalize(vec3(0.80, 0.20, 0.60)) * 0.20;
    //Yellow Potted flowers
    if (id == 37) color = normalize(vec3(0.80, 0.50, 0.05)) * 0.20;
    //Blue Potted flowers
    if (id == 38) color = normalize(vec3(0.00, 0.15, 1.00)) * 0.20;
    //White Potted flowers
    if (id == 39) color = normalize(vec3(0.80, 0.80, 0.80)) * 0.20;
    //Orange Potted flowers
    if (id == 40) color = normalize(vec3(1.00, 0.70, 0.05)) * 0.20;
	#endif

	//Jack-O-Lantern
	if (id == 41) color = vec3(JL_R, JL_G, JL_B) * JL_I;
    //Enchanting table
    if (id == 42) color = vec3(ET_R, ET_G, ET_B) * ET_I;
	//Red Candle
	if (id == 43) color = normalize(vec3(1.0, 0.1, 0.1));
	//Orange Candle
	if (id == 44) color = normalize(vec3(1.0, 0.5, 0.1));
	//Yellow Candle
	if (id == 45) color = normalize(vec3(1.0, 1.0, 0.1));
	//Brown Candle
	if (id == 46) color = normalize(vec3(0.7, 0.7, 0.0));
	//Green Candle
	if (id == 47) color = normalize(vec3(0.1, 1.0, 0.1));
	//Lime Candle
	if (id == 48) color = normalize(vec3(0.0, 1.0, 0.1));
	//Blue Candle
	if (id == 49) color = normalize(vec3(0.1, 0.1, 1.0));
	//Light blue Candle
	if (id == 50) color = normalize(vec3(0.5, 0.5, 1.0));
	//Cyan Candle
	if (id == 51) color = normalize(vec3(0.1, 1.0, 1.0));
	//Purple Candle
	if (id == 52) color = normalize(vec3(0.7, 0.1, 1.0));
	//Magenta Candle
	if (id == 53) color = normalize(vec3(1.0, 0.1, 1.0));
	//Pink Candle
	if (id == 54) color = normalize(vec3(1.0, 0.5, 1.0));
	//Black Candle
	if (id == 55) color = normalize(vec3(0.3, 0.3, 0.3));
	//White Candle
	if (id == 56) color = normalize(vec3(0.9, 0.9, 0.9));
	//Gray Candle
	if (id == 57) color = normalize(vec3(0.5, 0.5, 0.5));
	//Light gray Candle
	if (id == 58) color = normalize(vec3(0.7, 0.7, 0.7));
    //Candle
    if (id == 59) color = normalize(vec3(0.6, 0.5, 0.4));
    //Beacon
    if (id == 60) color = vec3(0.6, 0.7, 1.0) * 8.0;
	//Sculk Sensor
	if (id == 62) color = vec3(0.20, 0.55, 1.00) * 2.5;
	//Calibrated Sculk Sensor
	if (id == 63) color = vec3(1.00, 0.25, 0.75) * 2.5;
	//Fungi
	if (id == 64) color = vec3(1.0, 0.2, 0.1) * 0.1;
	//Crimson Stem & Hyphae
	if (id == 65) color = vec3(1.0, 0.2, 0.1) * 0.2;
	//Warped Stem & Hyphae
	if (id == 66) color = vec3(0.1, 0.5, 0.7) * 0.2;
	//Mob Spawner
	if (id == 69) color = vec3(0.1, 0.01, 0.15);
	//End Portal With Eye
	if (id == 71) color = vec3(0.1, 0.9, 0.3) * 0.5;
	//Zinc Ore
	if (id == 72) color = vec3(0.4);
	//Creaking Heart (Active)
	if (id == 73) color = vec3(1.0, 0.3, 0.1);

	#ifdef EMISSIVE_FLOWERS
    //Red Potted flowers
    if (id == 74) color = normalize(vec3(1.00, 0.05, 0.05)) * 0.20;
    //Pink Potted flowers
    if (id == 75) color = normalize(vec3(0.80, 0.20, 0.60)) * 0.20;
    //Yellow Potted flowers
    if (id == 76) color = normalize(vec3(0.80, 0.50, 0.05)) * 0.20;
    //Blue Potted flowers
    if (id == 77) color = normalize(vec3(0.00, 0.15, 1.00)) * 0.20;
    //White Potted flowers
    if (id == 78) color = normalize(vec3(0.80, 0.80, 0.80)) * 0.20;
    //Orange Potted flowers
    if (id == 79) color = normalize(vec3(1.00, 0.70, 0.05)) * 0.20;
	#endif

	//Generic emitters with different colors
	//Blocks in this range will emit their respective color
	//A good way to quickly make modded blocks emit light
	if (id == 194) color = normalize(vec3(1.00, 0.05, 0.05)) * 0.50; //block.10194, red
	if (id == 195) color = normalize(vec3(1.00, 0.70, 0.05)) * 0.50; //block.10195, orange
	if (id == 196) color = normalize(vec3(0.80, 0.50, 0.05)) * 0.50; //block.10196, yellow
	if (id == 197) color = normalize(vec3(0.10, 1.00, 0.10)) * 0.50; //block.10197, green
	if (id == 198) color = normalize(vec3(0.00, 0.15, 1.00)) * 0.50; //block.10198, blue
	if (id == 199) color = normalize(vec3(0.70, 0.10, 1.00)) * 0.50; //block.10199, purple
	if (id == 200) color = normalize(vec3(0.80, 0.80, 0.80)) * 0.50; //block.10200, white

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