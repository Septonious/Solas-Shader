#ifdef FSH
void getIntegratedEmission(inout float emission, inout vec2 lightmap, in vec4 albedo){
	float newEmissive = 0.0;

    if (mat > 100.9 && mat < 101.1){ // Stray
        newEmissive = float(length(albedo.rgb) > 0.999999999999999999 && albedo.r > 0.9019) * 0.25; // that was painful
    }

    if (mat > 101.9 && mat < 102.1){ // Witch
        newEmissive = float(albedo.g > 0.3 && albedo.r < 0.3);
    }

    if (mat > 102.9 && mat < 103.1){ // Magma Cube
        newEmissive = 0.75 + float(albedo.g > 0.5 && length(albedo.rgb) > 0.5) * 0.25;
        lightmap.x *= newEmissive;
    }

    if (mat > 103.9 && mat < 104.1){ // Drowned && Shulker
        newEmissive = float(length(albedo.rgb) > 0.99) * 0.25;
    }

    if (mat > 104.9 && mat < 105.1){ // JellySquid
        newEmissive = 0.025 + float(length(albedo.rgb) > 0.99) * 0.25;
        lightmap.x *= newEmissive;
    }

    if (mat > 105.9 && mat < 106.1){ // End Crystal
        newEmissive = float(albedo.r > 0.5 && albedo.g < 0.55) * 0.1;
        lightmap.x *= newEmissive;
    }
    
    #ifdef ENTITY_BRIGHT_PARTS_HIGHLIGHT
    newEmissive += float(length(albedo.rgb) > 0.85);
    #endif

	emission += newEmissive * EMISSION_STRENGTH;
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