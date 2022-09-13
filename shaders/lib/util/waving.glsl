const float PI = 3.14;
float TAUF = 6.28 * (frameTimeCounter * 24.0);

float GetNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

float get2DNoise(vec2 pos) {
    vec2 floorPos = floor(pos);
    vec2 fractPos = fract(pos);
    fractPos = fractPos * fractPos * (3.0 - 2.0 * fractPos);

    float harmonic0 = GetNoise(floorPos);
    float harmonic1 = GetNoise(floorPos + vec2(0.0, 1.0));
    float harmonic2 = GetNoise(floorPos + vec2(1.0, 0.0));
    float harmonic3 = GetNoise(floorPos + vec2(1.0, 1.0));

    float noiseA = mix(harmonic0, harmonic1, fractPos.y);
    float noiseB = mix(harmonic2, harmonic3, fractPos.y);

    return mix(noiseA, noiseB, fractPos.x) - 0.5;
}

vec3 calculateMovement(vec3 pos, float density, float speed, vec2 mult) {
    pos = pos * density + frametime * speed;
    vec3 wave = vec3(get2DNoise(pos.yz), get2DNoise(pos.xz + 0.25), get2DNoise(pos.xy + 0.5));

    return wave * vec3(mult, mult.x);
}

vec3 getWavingBlocks(vec3 pos, float istopv) {
    vec3 wave = vec3(0.0);
    vec3 worldPos = pos + cameraPosition;

    #ifdef WAVING_PLANT
    if (mc_Entity.x == 10100 && istopv > 0.9)
        wave += calculateMovement(worldPos, 0.35, 1.0, vec2(0.25, 0.06));
    if (mc_Entity.x == 10101 && (istopv > 0.9|| fract(worldPos.y + 0.005) > 0.01))
        wave += calculateMovement(worldPos, 0.7, 1.35, vec2(0.12, 0.06));
    if (mc_Entity.x == 10102 && (istopv > 0.9 || fract(worldPos.y + 0.005) > 0.01) ||
        mc_Entity.x == 10103)
        wave += calculateMovement(worldPos, 0.35, 1.15, vec2(0.15, 0.06));
    if (mc_Entity.x == 10104 && (istopv > 0.9 || fract(worldPos.y + 0.0675) > 0.01))
        wave += calculateMovement(worldPos, 0.35, 1.0, vec2(0.15, 0.06));
    if (mc_Entity.x == 10106)
        wave += calculateMovement(worldPos, 0.35, 1.25, vec2(0.06, 0.06));        
    if (mc_Entity.x == 10107 || mc_Entity.x == 10207)
        wave += calculateMovement(worldPos, 0.5, 1.25, vec2(0.06, 0.00));
    #endif

    #ifdef WAVING_LEAF
    if (mc_Entity.x == 10105)
        wave += calculateMovement(worldPos, 0.25, 1.0, vec2(0.08, 0.08));
    #endif

    pos += wave;

    return pos;
}