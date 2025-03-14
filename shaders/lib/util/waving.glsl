const float pi = 3.1415927;
float pi2wt = 6.2831854 * (frameTimeCounter * 24.0);

float GetNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

float Noise2D(vec2 pos) {
    vec2 flr = floor(pos);
    vec2 frc = fract(pos);
    frc = frc * frc * (3.0 - 2.0 * frc);

    float n00 = GetNoise(flr);
    float n01 = GetNoise(flr + vec2(0.0, 1.0));
    float n10 = GetNoise(flr + vec2(1.0, 0.0));
    float n11 = GetNoise(flr + vec2(1.0, 1.0));

    float n0 = mix(n00, n01, frc.y);
    float n1 = mix(n10, n11, frc.y);

    return mix(n0, n1, frc.x) - 0.5;
}

vec3 CalcMove(vec3 pos, float density, float speed, vec2 mult) {
    pos = pos * density + frameTimeCounter * speed;
    vec3 wave = vec3(Noise2D(pos.yz), Noise2D(pos.xz + 0.333), Noise2D(pos.xy + 0.667));
    return wave * vec3(mult, mult.x);
}

vec3 getWavingBlocks(vec3 worldPos, float istopv, float skyLightMap) {
    vec3 wave = vec3(0.0);

    if (skyLightMap > 0.0) {
        vec3 pos = worldPos + cameraPosition;

        #ifdef WAVING_PLANTS
        if (istopv > 0.9 && (mc_Entity.x == 10304 || (mc_Entity.x >= 10035 && mc_Entity.x <= 10040))) { // Grass and flowers
            wave += CalcMove(worldPos, 0.35, 1.0, vec2(0.125, 0.03));
        } else if ((mc_Entity.x == 10305 || mc_Entity.x == 10307 || mc_Entity.x == 10309 || mc_Entity.x == 10311 || mc_Entity.x == 10318) && (istopv > 0.9 || fract(pos.y + 0.005) > 0.01) || mc_Entity.x == 10306 || mc_Entity.x == 10308 || mc_Entity.x == 10310 || mc_Entity.x == 10312 || mc_Entity.x == 10319) { // Large Flowers (real big)
            wave += CalcMove(worldPos, 0.35, 0.95, vec2(0.15, 0.06));
        } else if (mc_Entity.x == 10315) { // Vines
            wave += CalcMove(worldPos, 0.35, 1.25, vec2(0.06, 0.06)); 
        }
        #endif

        #ifdef WAVING_LEAVES
        if (mc_Entity.x == 10314) wave += CalcMove(worldPos, 0.25, 1.0, vec2(0.04, 0.04));
        #endif

        return worldPos + wave * skyLightMap;
    }

    return worldPos;
}