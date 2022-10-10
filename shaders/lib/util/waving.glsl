float getNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

float get2DNoise(vec2 pos) {
    vec2 floorPos = floor(pos);
    vec2 fractPos = fract(pos);
    fractPos = fractPos * fractPos * (3.0 - 2.0 * fractPos);

    float harmonic0 = getNoise(floorPos);
    float harmonic1 = getNoise(floorPos + vec2(0.0, 1.0));
    float harmonic2 = getNoise(floorPos + vec2(1.0, 0.0));
    float harmonic3 = getNoise(floorPos + vec2(1.0, 1.0));

    float noiseA = mix(harmonic0, harmonic1, fractPos.y);
    float noiseB = mix(harmonic2, harmonic3, fractPos.y);

    return mix(noiseA, noiseB, fractPos.x) - 0.5;
}

vec3 calculateMovement(vec3 pos, float density, float speed, vec2 mult) {
    pos = pos * density + frameTimeCounter * speed * WAVING_SPEED;
    vec3 wave = vec3(get2DNoise(pos.yz), get2DNoise(pos.xz + 0.25), get2DNoise(pos.xy + 0.5));

    return wave * vec3(mult, mult.x) * WAVING_AMPLITUDE;
}

vec3 getWavingBlocks(vec3 pos, float istopv, float skyLightMap) {
    vec3 wave = vec3(0.0);

    if (skyLightMap > 0.0) {
        vec3 worldPos = pos + cameraPosition;

        #ifdef WAVING_PLANTS
        if (mc_Entity.x == 4 && istopv > 0.9) { // Grass
            wave += calculateMovement(worldPos, 0.75, 1.0, vec2(0.125, 0.03));
        } else if (mc_Entity.x == 5 && (istopv > 0.9|| fract(worldPos.y + 0.005) > 0.01)) { // Small Flowers
            wave += calculateMovement(worldPos, 0.65, 1.10, vec2(0.06, 0.03));
        } else if (mc_Entity.x == 6 && (istopv > 0.9 || fract(worldPos.y + 0.005) > 0.01) || mc_Entity.x == 7) { // Large Flowers (real big)
            wave += calculateMovement(worldPos, 0.35, 1.05, vec2(0.06, 0.03));
        } else if (mc_Entity.x == 10) { // Vines
            wave += calculateMovement(worldPos, 0.55, 0.95, vec2(0.03, 0.03)); 
        }
        #endif

        #ifdef WAVING_LEAVES
        if (mc_Entity.x == 9) wave += calculateMovement(worldPos, 0.25, 1.0, vec2(0.04, 0.04));
        #endif
    }

    return pos + wave * skyLightMap;
}