void sampleNebulaNoise(vec2 coord, inout float colorMixer, inout float noise) {
    colorMixer = texture2D(noisetex, coord * 0.25).r;
    noise = texture2D(noisetex, coord * 0.50).r;
    noise *= colorMixer;
    noise *= texture2D(noisetex, coord * 0.125).r;
    noise *= 4.0;
}

float getSpiralWarping(vec2 coord){
	float whirl = -10.0;
	float arms = 10.0;

    coord = vec2(atan(coord.y, coord.x) + frameTimeCounter * 0.1, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow8(1.0 - coord.y) * 2.0;
    float spiral = sin((coord.x + sqrt(coord.y) * whirl) * arms) + center - coord.y;

    return clamp(spiral * 0.1, 0.0, 1.0);
}

#if MC_VERSION >= 12100
float endFlashIntensitySqrt = sqrt(endFlashIntensity);

vec4 getSupernovaAtPos(in vec3 flashPos, in vec3 worldPos) {
    vec2 flashCoord = flashPos.xz / (flashPos.y + length(flashPos));
    vec2 blackHoleCoord = worldPos.xz / (length(worldPos) + worldPos.y) - flashCoord;

    float nebulaNoise = 0.0;
    float nebulaColorMixer = 0.0;
    sampleNebulaNoise(blackHoleCoord, nebulaColorMixer, nebulaNoise);
          nebulaColorMixer = pow4(nebulaColorMixer) * 6.0;

    float endFlashPoint = 1.0 - clamp(length(blackHoleCoord), 0.0, 1.0);
    float animation = endFlashIntensitySqrt * 15.0;
    float visibility = pow(endFlashPoint, 20.0 - animation) * max(1.0 - (1.0 + endFlashIntensity) * pow(endFlashPoint, 24.0 - animation), 0.0);

    return vec4(nebulaNoise, nebulaColorMixer, visibility, endFlashPoint);
}
#endif

void drawEndNebula(inout vec3 color, in vec3 worldPos, in float VoU, in float VoS) {
    #ifdef END_BLACK_HOLE
    //Prepare black hole parameters for warping the nebula
    float hole = pow(pow4(pow32(VoS)), END_BLACK_HOLE_SIZE);
    float gravityLens = hole;
    hole *= hole;
    hole *= hole;

    vec3 wSunVec = mat3(gbufferModelViewInverse) * sunVec;
    vec2 sunCoord = wSunVec.xz / (wSunVec.y + length(wSunVec));
    vec2 blackHoleCoord = worldPos.xz / (length(worldPos) + worldPos.y) - sunCoord;
    float warping = getSpiralWarping(blackHoleCoord);
         blackHoleCoord.x *= 0.75 - abs(VoU) * 0.25;
         blackHoleCoord.y *= 4.0;
    #endif

    //Ender Nebula
    vec2 nebulaCoord = worldPos.xz / (length(worldPos.y) + length(worldPos.xyz));
    #ifdef END_BLACK_HOLE
         nebulaCoord += warping * gravityLens;
    #endif

    float nebulaNoise = 0.0;
    float nebulaColorMixer = 0.0;
    sampleNebulaNoise(nebulaCoord, nebulaColorMixer, nebulaNoise);
          nebulaColorMixer = pow4(nebulaColorMixer) * 6.0;

    float nebulaVisibility = (0.175 - pow3(VoS) * 0.175) + pow24(VoS) * 0.825;
    vec3 nebula = mix(vec3(5.6, 2.2, 0.2), vec3(0.1, 2.8, 1.1), nebulaColorMixer) * nebulaNoise * nebulaNoise * nebulaVisibility;
         nebula *= max(1.0 - pow32(VoS) * 1.0, 0.0);
         nebula *= length(nebula) * END_NEBULA_BRIGHTNESS;

    color += nebula;

    //Supernova in 1.21.8
    #if MC_VERSION >= 12100 && defined END_FLASHES
    vec4 supernova = getSupernovaAtPos(mat3(gbufferModelViewInverse) * endFlashPosition, worldPos);

    vec3 supernovaNebula = mix(normalize(endFlashCol), normalize(vec3(1.0, 1.8, 3.2)), supernova.y) * 4.0 * supernova.x * supernova.x * supernova.z;
         supernovaNebula *= length(supernovaNebula);
    color += pow32(supernova.a * supernova.a) * endLightColSqrt * endFlashIntensity;
    color += supernovaNebula * endFlashIntensitySqrt * END_FLASH_BRIGHTNESS;
    #endif

    //Black Hole
    #ifdef END_BLACK_HOLE
    const vec3 blackHoleColor = vec3(5.6, 2.2, 0.2);

    float innerRing = pow2(hole * 3.0);
          innerRing *= float(innerRing > 0.2) * (1.0 - 6.0 * hole) * 64.0;
          innerRing = max(innerRing, 0.0);
          hole = clamp(hole * 8.0, 0.0, 1.0);

    float torus = 1.0 - clamp(length(blackHoleCoord), 0.0, 1.0);
          torus = pow(pow16(torus * torus), END_BLACK_HOLE_SIZE * 1.25);
    float torusNoise = texture2D(noisetex, vec2(blackHoleCoord.x * 4.0 + frameTimeCounter * 0.05, blackHoleCoord.y)).r;

    color += mix(blackHoleColor, vec3(4.0), hole * hole) * hole * hole * 2.0;
    color *= 1.0 - hole;
    color += vec3(innerRing);
    color += mix(blackHoleColor, vec3(2.0), sqrt(torus)) * torus * 4.0 * torusNoise;
    #endif
}