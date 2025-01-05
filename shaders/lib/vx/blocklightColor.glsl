const vec3[] blocklightColorArray = vec3[](
	//Air
	vec3(0.0),
	//Non-emissive blocks
	vec3(0.0),
	//Glow Lichen, Sea Pickle
	vec3(GLSP_R, GLSP_G, GLSP_B) * GLSP_I,
	//Brewing Stand
	vec3(BS_R, BS_G, BS_B) * BS_I,
	//Torch, Lantern, Campfire, Fire
	vec3(TLCF_R, TLCF_G, TLCF_B) * TLCF_I,
	//Soul Torch, Soul Lantern, Soul Campfire, Soul Fire
	vec3(SOUL_R, SOUL_G, SOUL_B) * SOUL_I,
	//End Rod
	vec3(ER_R, ER_G, ER_B) * ER_I,
	//Sea Lantern
	vec3(SL_R, SL_G, SL_B) * SL_I,
	//Glowstone
	vec3(GS_R, GS_G, GS_B) * GS_I,
	//Shroomlight, Redstone Lamp
	vec3(SLRL_R, SLRL_G, SLRL_B) * SLRL_I,
	//Respawn Anchor, Crying Obsidian
	vec3(RACO_R, RACO_G, RACO_B) * RACO_I,
	//Lava
	vec3(LAVA_R, LAVA_G, LAVA_B + 0.02) * LAVA_I,
	//Cave Berries
	vec3(CB_R, CB_G, CB_B) * CB_I,
	//Amethyst
	vec3(METH_lmao_R, METH_lmao_G, METH_lmao_B) * METH_lmao_I,
	#ifdef EMISSIVE_CONCRETE
	//Red Concrete
	vec3(1.00, 0.00, 0.00) * 3.0,
	//Orange Concrete
	vec3(1.00, 0.20, 0.00) * 3.0,
	//Yellow Concrete
	vec3(1.00, 0.60, 0.10) * 3.0,
	//Lime Concrete
	vec3(0.00, 1.00, 0.10) * 3.0,
	//Light Blue Concrete
	vec3(0.00, 0.40, 1.00) * 3.0,
	//Magenta Concrete
	vec3(1.00, 0.00, 1.00) * 3.5,
	#else
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	#endif
	//Magma Block
	vec3(MB_R, MB_G, MB_B) * MB_I,
	#ifdef EMISSIVE_ORES
    //Emerald Ore
    normalize(vec3(0.05, 1.00, 0.15)) * 0.35,
    //Diamond Ore
    normalize(vec3(0.10, 0.40, 1.00)) * 0.35,
    //Copper Ore
    normalize(vec3(0.60, 0.70, 0.30)) * 0.35,
    //Lapis Ore
    normalize(vec3(0.00, 0.10, 1.20)) * 0.35,
    //Gold Ore
    normalize(vec3(1.00, 0.75, 0.10)) * 0.35,
    //Iron Ore
    normalize(vec3(0.70, 0.40, 0.30)) * 0.35,
    //Redstone Ore
    normalize(vec3(1.00, 0.05, 0.00)) * 0.35,
	#else
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	#endif
    //Lit Redstone Ore
    vec3(1.00, 0.05, 0.00),
    //Powered Rails
    vec3(1.00, 0.05, 0.00),
    //Nether Portal
    vec3(NP_R, NP_G, NP_B) * NP_I,
    //Orchre Froglight
    normalize(vec3(1.00, 0.55, 0.25)) * 5.5,
    //Verdant Froglight
    normalize(vec3(0.0, 1.00, 0.05)) * 5.5,
    //Pearlescent Froglight
    normalize(vec3(1.00, 0.20, 0.90)) * 5.5,
	#ifdef EMISSIVE_FLOWERS
    //Red flowers
    normalize(vec3(1.00, 0.05, 0.05)) * 0.20,
    //Pink flowers
    normalize(vec3(0.80, 0.20, 0.60)) * 0.20,
    //Yellow flowers
    normalize(vec3(0.80, 0.50, 0.05)) * 0.20,
    //Blue flowers
    normalize(vec3(0.00, 0.15, 1.00)) * 0.20,
    //White flowers
    normalize(vec3(0.80, 0.80, 0.80)) * 0.20,
    //Orange flowers
    normalize(vec3(1.00, 0.70, 0.05)) * 0.20,
	#else
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	#endif
	//Jack-O-Lantern
	vec3(1.00, 0.55, 0.20) * 3.5,
    //Enchanting table
    vec3(0.15, 0.50, 1.00) * 2.5,
	//Red Candle
	normalize(vec3(1.0, 0.1, 0.1)),
	//Orange Candle
	normalize(vec3(1.0, 0.5, 0.1)),
	//Yellow Candle
	normalize(vec3(1.0, 1.0, 0.1)),
	//Brown Candle
	normalize(vec3(0.7, 0.7, 0.0)),
	//Green Candle
	normalize(vec3(0.1, 1.0, 0.1)),
	//Lime Candle
	normalize(vec3(0.0, 1.0, 0.1)),
	//Blue Candle
	normalize(vec3(0.1, 0.1, 1.0)),
	//Light blue Candle
	normalize(vec3(0.5, 0.5, 1.0)),
	//Cyan Candle
	normalize(vec3(0.1, 1.0, 1.0)),
	//Purple Candle
	normalize(vec3(0.7, 0.1, 1.0)),
	//Magenta Candle
	normalize(vec3(1.0, 0.1, 1.0)),
	//Pink Candle
	normalize(vec3(1.0, 0.5, 1.0)),
	//Black Candle
	normalize(vec3(0.3, 0.3, 0.3)),
	//White Candle
	normalize(vec3(0.9, 0.9, 0.9)),
	//Gray Candle
	normalize(vec3(0.5, 0.5, 0.5)),
	//Light gray Candle
	normalize(vec3(0.7, 0.7, 0.7)),
    //Candle
    normalize(vec3(0.6, 0.5, 0.4)),
    //Beacon
    vec3(0.6, 0.7, 1.0) * 8.0,
	//Sculks, non-emissive
	vec3(0.0),
	//Sculk Sensor
	vec3(0.20, 0.55, 1.00) * 2.5,
	//Calibrated Sculk Sensor
	vec3(1.00, 0.25, 0.75) * 2.5,
	//Fungi
	vec3(1.0, 0.2, 0.1) * 0.1,
	//Crimson Stem & Hyphae
	vec3(1.0, 0.2, 0.1) * 0.2,
	//Warped Stem & Hyphae
	vec3(0.1, 0.5, 0.7) * 0.2,
	//Warts
	vec3(0.0),
	vec3(0.0),
	//Mob Spawner
	vec3(0.1, 0.01, 0.15),
	//Unlit Redstone Lamp
	vec3(0.0),
	//End Portal With Eye
	vec3(0.1, 0.9, 0.3) * 0.5,
	//Zinc Ore
	vec3(0.4),
	//Creaking Heart (Active)
	vec3(1.0, 0.3, 0.1),
	#ifdef EMISSIVE_FLOWERS
    //Red Potted flowers
    normalize(vec3(1.00, 0.05, 0.05)) * 0.20,
    //Pink Potted flowers
    normalize(vec3(0.80, 0.20, 0.60)) * 0.20,
    //Yellow Potted flowers
    normalize(vec3(0.80, 0.50, 0.05)) * 0.20,
    //Blue Potted flowers
    normalize(vec3(0.00, 0.15, 1.00)) * 0.20,
    //White Potted flowers
    normalize(vec3(0.80, 0.80, 0.80)) * 0.20,
    //Orange Potted flowers
    normalize(vec3(1.00, 0.70, 0.05)) * 0.20,
	#else
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	vec3(0.0),
	#endif
	//Buffer
	vec3(0.0)
);

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