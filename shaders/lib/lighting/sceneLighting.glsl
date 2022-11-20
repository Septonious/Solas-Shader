#if defined OVERWORLD || defined END
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
vec3 lightVec = sunVec;
#endif

#if defined BLOOM_COLORED_LIGHTING || defined GLOBAL_ILLUMINATION
#ifdef GBUFFERS_WATER
#undef GLOBAL_ILLUMINATION
#undef BLOOM_COLORED_LIGHTING
#endif
#endif

#ifdef DYNAMIC_HANDLIGHT
vec3 getHandLightColor(float handlight) {
    vec3 handLightColor = blockLightCol;

    if (handlight > 0.0) {
        if (heldItemId == 63 || heldItemId2 == 63 || heldItemId == 51 || heldItemId2 == 51 || heldItemId == 60 || heldItemId2 == 60) handLightColor = vec3(0.23, 0.54, 0.94);
        if (heldItemId == 62 || heldItemId2 == 62) handLightColor = vec3(0.70, 0.54, 0.33);
        if (heldItemId == 59 || heldItemId2 == 59) handLightColor = vec3(0.78, 0.47, 0.15);
        if (heldItemId == 58 || heldItemId2 == 58) handLightColor = vec3(0.80, 0.90, 1.20);
        if (heldItemId == 57 || heldItemId2 == 57) handLightColor = vec3(0.31, 0.44, 0.59);
        if (heldItemId == 56 || heldItemId2 == 56) handLightColor = vec3(0.86, 0.62, 0.31);
        if (heldItemId == 55 || heldItemId2 == 55) handLightColor = vec3(0.73, 0.43, 0.23);
        if (heldItemId == 54 || heldItemId2 == 54) handLightColor = vec3(1.10, 0.50, 1.50);
        if (heldItemId == 53 || heldItemId2 == 53 || heldItemId == 61 || heldItemId2 == 61 || heldItemId == 64 || heldItemId2 == 64) handLightColor = vec3(0.86, 0.62, 0.31);
        if (heldItemId == 52 || heldItemId2 == 52) handLightColor = vec3(1.00, 0.31, 0.07);
    }

    return mix(handLightColor * handlight, vec3(0.0), 0.25);
}
#endif

#ifdef BLOOM_COLORED_LIGHTING
void computeBCL(inout vec3 blockLighting, in vec3 bloom, in float directionalBloom, in float lViewPos, in float blockLightMap, in float skyLightMap) {
    float bloomLightMap = pow2(blockLightMap) + blockLightMap * 0.5;
    float radius = mix(COLORED_LIGHTING_RADIUS - 0.1, COLORED_LIGHTING_RADIUS, skyLightMap);

    bloomLightMap += mix((1.0 - clamp(lViewPos * 0.05, 0.0, 1.0)) * 0.5, 0.0, min(bloomLightMap, 1.0));

	vec3 coloredLight = clamp(0.0625 * bloom * pow(getLuminance(bloom), radius), 0.0, 1.0) * 16.0;
    
    blockLighting += coloredLight * bloomLightMap * directionalBloom * COLORED_LIGHTING_STRENGTH;
}
#endif

#ifndef GBUFFERS_TERRAIN
void getSceneLighting(inout vec3 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, in vec2 lightmap, in float emission, in float leaves, in float foliage, in float specular) {
#else
void getSceneLighting(inout vec3 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, in vec2 lightmap, inout float emission, in float leaves, in float foliage, in float specular) {
#endif
    #ifdef GBUFFERS_TERRAIN
	if (foliage > 0.9) {
		normal = upVec;
	}
    #endif

    lightmap.y = sqrt(lightmap.y);

    float lViewPos = length(viewPos);
    float ao = clamp(pow2(color.a), 0.0, 1.0);

    //Vanilla Directional Lighting
	float NoL = clamp(dot(normal, lightVec), 0.0, 1.0);
	float NoU = clamp(dot(normal, upVec), -1.0, 1.0);
	float NoE = clamp(dot(normal, eastVec), -1.0, 1.0);

	float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;

    //Block Lighting//
    vec3 blockLighting = vec3(0.0);

    #ifdef SHIMMER_MOD_SUPPORT
    float blockLightMap = min(pow4(lightmap.x) * 2.0 + pow2(lightmap.x) * 0.125, 1.0) * (1.0 - emission);
    #else
    float blockLightMap = min(pow8(lightmap.x) + pow4(lightmap.x) * 0.5, 1.0) * (1.0 - emission);
    #endif

	#ifdef DYNAMIC_HANDLIGHT
	float heldLightValue = max(float(heldBlockLightValue), float(heldBlockLightValue2));
	float handlight = clamp((heldLightValue - 4.0 * lViewPos) * 0.025, 0.0, 1.0);
	#endif

    #if defined BLOOM_COLORED_LIGHTING || defined GLOBAL_ILLUMINATION
    vec3 bloom = texture2D(gaux4, gl_FragCoord.xy / vec2(viewWidth, viewHeight)).rgb;
         bloom = pow4(bloom) * 128.0;
    float directionalBloom = clamp(abs(dot(normalize(bloom), normal)), 0.0, 1.0);
    #endif

    #if defined SHIMMER_MOD_SUPPORT
    //COLORED LIGHTING USING SHIMMER MOD
    vec3 coloredLight = getColoredLighting(worldPos, blockLightMap) * BLOCKLIGHT_I;
    blockLighting = blockLightCol * blockLightMap + coloredLight * (1.0 - emission);
    #elif defined BLOOM_COLORED_LIGHTING
    //BLOOM BASED COLORED LIGHTING
    blockLighting = blockLightCol * blockLightMap;

    computeBCL(blockLighting, bloom, directionalBloom, lViewPos, lightmap.x, lightmap.y);
    #else
    blockLighting = blockLightCol * blockLightMap;
    #endif

    #ifdef DYNAMIC_HANDLIGHT
    blockLighting += getHandLightColor(handlight);
    #endif

    //Main Scene Lighting (Sunlight & Shadows)
    #if defined OVERWORLD || defined END
    float scattering = 0.0;

    vec3 shadow = vec3(0.0);

    //Subsurface Scattering & Specular Highlight
    #ifdef OVERWORLD
    specular *= clamp(NoU - 0.01, 0.0, 1.0);

    float subsurface = leaves + foliage;

    //Subsurface Scattering & Specular Highlight
    if (subsurface > 0.0 || specular > 0.0) {
        float VoL = clamp(dot(normalize(viewPos), lightVec), 0.0, 1.0);
        VoL = pow16(VoL) * 0.5 + pow32(pow16(VoL));
        scattering = VoL * subsurface + VoL * specular;
        scattering = clamp(scattering * 2.0, 0.0, 1.0);
        NoL = mix(NoL, 1.0, subsurface * 0.5);
        NoL = mix(NoL, 1.0, scattering);
        lightCol *= 1.0 + scattering;
    }
    #endif

    if (NoL > 0.0001) {
        //Shadows without peter-panning from Emin's Complementary Reimagined shaderpack, tysm for allowing me to use them ^^
        //Developed by Emin#7309 and gri573#7741
        #ifdef TAA
        float dither = fract(Bayer64(gl_FragCoord.xy) + frameTimeCounter * 16.0);
        #else
        float dither = 0.0;
        #endif

        float shadowLength = shadowDistance * 0.9166667 - length(vec4(worldPos.x, worldPos.y, worldPos.y, worldPos.z));

        if (shadowLength > 0.000001) {
            #ifdef OVERWORLD
            float offset = shadowOffset;
            if (subsurface > 0.5) {
                offset = mix(offset * 2.0, offset, clamp(lViewPos * 0.025, 0.0, 1.0));
            }
            #else
            float offset = shadowOffset;
            #endif

            vec3 worldPosM = worldPos;

            #ifndef GBUFFERS_TEXTURED
                // Shadow bias without peter-panning
                vec3 worldNormal = normalize(ToWorld(normal * 1000.0));
                vec3 bias = worldNormal * min(0.1 + length(worldPos) / 200.0, 0.5) * (2.0 - NoL);
                
                #ifdef GBUFFERS_WATER
                    bias *= 0.5;
                    worldPosM += 1.0 - lightmap.y;
                #endif

                worldPosM += bias;
            #else
                vec3 centerworldPos = floor(worldPosM + cameraPosition) - cameraPosition + 0.5;
                worldPosM = mix(centerworldPos, worldPosM + vec3(0.0, 0.02, 0.0), lightmap.y);
            #endif

            vec3 shadowPos = calculateShadowPos(worldPosM);

            float viewLengthFactor = 1.0 - clamp(length(viewPos.xz) * 0.01, 0.0, 1.0);

            shadow = computeShadow(shadowPos, offset, dither, lightmap.y, color.a, viewLengthFactor) * lightmap.y;
        }
    }

    vec3 fullShadow = shadow * NoL;
    
    #ifdef OVERWORLD
    float rainFactor = 1.0 - rainStrength * 0.8;

    #ifdef GLOBAL_ILLUMINATION
    bloom = clamp(bloom * pow(getLuminance(bloom), GLOBAL_ILLUMINATION_RADIUS), 0.0, 1.0) * 2.0;

    #ifdef OVERWORLD
    ambientCol *= vec3(1.0) + bloom * sunVisibility * rainFactor;
    #endif
    #endif

    vec3 sceneLighting = mix(ambientCol * pow4(lightmap.y), lightCol * max(lightmap.y, 0.125), fullShadow * rainFactor);
    sceneLighting *= 1.0 + scattering * shadow;
    #endif

    #ifdef END
    #ifdef GLOBAL_ILLUMINATION
    vec3 sceneLighting = mix(endAmbientCol * 0.25 * (vec3(1.0) + bloom), endLightCol * 0.25, fullShadow);
    #else
    vec3 sceneLighting = mix(endAmbientCol * 0.25, endLightCol * 0.25, fullShadow);
    #endif
    #endif
    #endif

    #ifdef NETHER
    vec3 sceneLighting = pow(netherColSqrt, vec3(0.25)) * 0.125;
    #endif

    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao, (1.0 - ao) * (1.0 - blockLightMap) * float(emission == 0.0));

    albedo = pow(albedo, vec3(2.2));

    albedo *= sceneLighting + blockLighting + (albedo * emission * EMISSION_STRENGTH) + nightVision * 0.25 + (minLightCol * (1.0 - lightmap.y));
    albedo *= vanillaDiffuse;

    albedo = sqrt(max(albedo, vec3(0.0)));

    #ifdef GLOBAL_ILLUMINATION
    #ifdef OVERWORLD
    float giVisibility = length(fullShadow * rainFactor * sunVisibility);
    #else
    float giVisibility = length(fullShadow) * 0.25;
    #endif

    if (giVisibility != 0.0) {
        emission += mix(0.0, GLOBAL_ILLUMINATION_STRENGTH * float(emission == 0.0), giVisibility);
    }
    #endif
}