

vec3 calculateWaving(vec3 worldPos, float wind) {
    float strength = sin(wind + worldPos.z + worldPos.y) * 0.25 + 0.05;

    float d0 = sin(wind * 0.0125);
    float d1 = sin(wind * 0.0090);
    float d2 = sin(wind * 0.0105);

    return vec3(sin(wind * 0.0065 + d0 + d1 - worldPos.x + worldPos.z + worldPos.y), 
                sin(wind * 0.0225 + d1 + d2 + worldPos.x - worldPos.z + worldPos.y),
                sin(wind * 0.0015 + d2 + d0 + worldPos.z + worldPos.y - worldPos.y)) * strength;
}

vec3 calculateMovement(vec3 worldPos, float density, float speed, vec2 mult, float viewLength) {
    vec3 wave = calculateWaving(worldPos * density, frameTimeCounter * speed * WAVING_SPEED * viewLength);

    return wave * vec3(mult, mult.x) * WAVING_AMPLITUDE;
}

vec3 getWavingBlocks(vec3 worldPos, float istopv, float skyLightMap) {
    vec3 wave = vec3(0.0);

    if (skyLightMap > 0.0) {
        //float viewLength = clamp(length(worldPos) * 0.5, 0.0, 1.0);
        float viewLength = 1.0;
        vec3 pos = worldPos + cameraPosition;

        #ifdef WAVING_PLANTS
        if (istopv > 0.9 && (mc_Entity.x == 10304 || (mc_Entity.x >= 10035 && mc_Entity.x <= 10040))) { // Grass
            wave += calculateMovement(pos, 1.5, 1.0, vec2(0.1, 0.04), viewLength) * (3.0 - pow(viewLength, 0.25) * 2.0);
        } else if ((mc_Entity.x == 10305 || mc_Entity.x == 10307 || mc_Entity.x == 10309 || mc_Entity.x == 10311 || mc_Entity.x == 10318) && (istopv > 0.9 || fract(pos.y + 0.005) > 0.01) || mc_Entity.x == 10306 || mc_Entity.x == 10308 || mc_Entity.x == 10310 || mc_Entity.x == 10312 || mc_Entity.x == 10319) { // Large Flowers (real big)
            wave += calculateMovement(pos, 0.85, 0.75, vec2(0.12, 0.06), viewLength);
        } else if (mc_Entity.x == 10315) { // Vines
            wave += calculateMovement(pos, 0.60, 0.95, vec2(0.04, 0.04), viewLength); 
        }
        #endif

        #ifdef WAVING_LEAVES
        if (mc_Entity.x == 10314) wave += calculateMovement(pos, 0.75, 1.1, vec2(0.04, 0.04), viewLength);
        #endif

        return worldPos + wave * skyLightMap;
    }

    return worldPos;
}