const vec3[] blocklightColorArray = vec3[](
	//Air
	vec3(0.0),
	//Non-emissive blocks
	vec3(0.0),
	//Glow Lichen, Sea Pickle
	vec3(0.50, 0.80, 0.70) * 0.1,
	//Brewing Stand
	vec3(1.00, 0.75, 0.10) * 1.5,
	//Torch, Lantern, Campfire, Fire
	vec3(1.00, 0.5, 0.15) * 3.5,
	//Soul Torch, Soul Lantern, Soul Campfire, Soul Fire
	vec3(0.10, 0.60, 1.00) * 3.5,
	//End Rod
	vec3(1.00, 0.50, 0.90) * 3.5,
	//Sea Lantern
	vec3(0.70, 0.90, 1.00) * 6.5,
	//Glowstone
	vec3(1.00, 0.60, 0.30) * 5.5,
	//Shroomlight, Redstone Lamp
	vec3(1.00, 0.30, 0.10) * 4.5,
	//Respawn Anchor
	vec3(0.60, 0.05, 1.00),
	//Lava
	vec3(1.00, 0.18, 0.02) * 5.0,
	//Cave Berries
	vec3(1.00, 0.40, 0.10) * 2.5,
	//Amethyst
	vec3(0.80, 0.30, 1.00) * 2.0,
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
	//Magma Block
	vec3(1.00, 0.20, 0.05) * 2.00,
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
    vec3(0.60, 0.05, 1.00) * 5.0,
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
	vec3(0.0),
	//Crimson Stem & Hyphae
	vec3(1.0, 0.2, 0.1) * 0.2,
	//Warped Stem & Hyphae
	vec3(0.1, 0.5, 0.7) * 0.2,
	//Spawner, refuses to work
	vec3(0.1, 0.01, 0.15),
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