#if defined OVERWORLD || defined END
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
vec3 lightVec = sunVec;
#endif

#ifdef DYNAMIC_HANDLIGHT
#include "/lib/lighting/dynamicHandLight.glsl"
#endif

#ifdef BLOOM_COLORED_LIGHTING
void computeBCL(inout vec3 blockLighting, in vec3 bloom, in float lViewPos, in float directionalBloom, in float blockLightMap, in float skyLightMap) {
    float bloomLightMap = blockLightMap * blockLightMap * 1.25 + blockLightMap * 0.5 + 0.2;
    float radius = mix(COLORED_LIGHTING_RADIUS - 0.1, COLORED_LIGHTING_RADIUS, skyLightMap);

	vec3 coloredLight = clamp(0.0625 * bloom * pow(getLuminance(bloom), radius), 0.0, 1.0) * 16.0;
    
    blockLighting += coloredLight * bloomLightMap * directionalBloom * COLORED_LIGHTING_STRENGTH;
}
#endif

#ifdef GBUFFERS_TERRAIN
void getSceneLighting(inout vec3 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, in vec2 lightmap,
                      in float NoU, in float NoL, in float NoE, inout float emission, in float leaves, in float foliage, in float specular) {
#else
void getSceneLighting(inout vec3 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, in vec2 lightmap,
                      in float NoU, in float NoL, in float NoE, in float emission, in float leaves, in float foliage, in float specular) {
#endif
    //Variables
    float lViewPos = length(viewPos);
    float ao = clamp(color.a * color.a, 0.0, 1.0);

    //Vanilla Directional Lighting
	float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;

    //Block Lighting//
    #ifdef SHIMMER_MOD_SUPPORT
    float blockLightMap = min(pow4(lightmap.x) * 2.0 + lightmap.x * lightmap.x * 0.125, 1.0) * int(emission == 0.0);
    #else
    float blockLightMap = min(pow8(lightmap.x) + pow4(lightmap.x) * 0.5, 1.0) * int(emission == 0.0);
    #endif
    
    vec3 blockLighting = blockLightCol * blockLightMap;

    #if (defined BLOOM_COLORED_LIGHTING || defined GLOBAL_ILLUMINATION) && !defined GBUFFERS_WATER
    vec3 bloom = texture2D(gaux1, screenPos.xy).rgb;
         bloom = pow4(bloom) * 128.0;
    float directionalBloom = clamp(abs(dot(normalize(bloom), normal)) + 0.2, 0.0, 1.0);
    #endif

    #if defined SHIMMER_MOD_SUPPORT
    //World Space Colored Lighting via Shimmer Mod
    blockLighting += getColoredLighting(worldPos, blockLightMap) * BLOCKLIGHT_I * int(emission == 0.0);
    #elif defined BLOOM_COLORED_LIGHTING
    //Bloom Based Colored Lighting
    #if !defined GBUFFERS_WATER
    if (emission == 0.0) computeBCL(blockLighting, bloom, lViewPos, directionalBloom, lightmap.x, lightmap.y);
    #endif
    #endif

    #ifdef DYNAMIC_HANDLIGHT
    blockLighting += getHandLightColor(lViewPos);
    #endif

    //Main Scene Lighting (Sunlight & Shadows)
    #if defined OVERWORLD || defined END
    vec3 shadow = vec3(0.0);
    float subsurface = 0.0;

    //Subsurface Scattering & Specular Highlight
    #ifdef OVERWORLD
    subsurface = leaves + foliage;

    //Subsurface Scattering & Specular Highlight
    float VoL = dot(normalize(viewPos), lightVec);
	      VoL = clamp(VoL * 0.5 + 0.5, 0.0, 1.0);
	      VoL = 0.01 / (1.0 - 0.99 * VoL) - 0.01;
    float scattering = clamp((VoL + sqrt(VoL)) * (1.0 + specular * 3.0), 0.0, 0.5 + subsurface * 0.2 + specular * 0.8);

    NoL = mix(NoL, 0.5 + min(scattering * 0.5, 0.5), subsurface * (0.5 + min(scattering * 0.5, 0.5)));
    lightCol *= 1.0 + scattering;
    #endif

    if (NoL > 0.0001) {
        //Shadows without peter-panning from Emin's Complementary Reimagined shaderpack, tysm for allowing me to use them ^^
        //Developed by Emin#7309 and gri573#7741
        #ifdef TAA
        float dither = fract(Bayer64(gl_FragCoord.xy) + frameTimeCounter * 16.0) / 16.0 * (1.0 + subsurface * 3.0);
        #else
        float dither = 0.0;
        #endif

        float shadowLength = shadowDistance * 0.9166667 - length(vec4(worldPos.x, worldPos.y, worldPos.y, worldPos.z));

        if (shadowLength > 0.000001) {
            vec3 worldPosM = worldPos;

            #ifndef GBUFFERS_TEXTURED
                //Shadow bias without peter-panning
                vec3 worldNormal = normalize(ToWorld(normal * 100000.0));
                vec3 bias = worldNormal * min(0.1 + length(worldPos) / 250.0, 0.75);
                
                //Light leaking fix from Complementary
                if (lightmap.y < 0.001) {
                    vec3 edgeFactor = 0.2 * (0.5 - fract(worldPosM + cameraPosition + worldNormal * 0.01));
                    worldPosM += (1.0 - ao) * edgeFactor;
                }

                worldPosM += bias;
            #else
                vec3 centerworldPos = floor(worldPosM + cameraPosition) - cameraPosition + 0.5;
                worldPosM = mix(centerworldPos, worldPosM + vec3(0.0, 0.02, 0.0), lightmap.y);
            #endif

            shadow = computeShadow(calculateShadowPos(worldPosM), shadowOffset * (1.0 + subsurface * 2.0), dither, lightmap.y, ao, subsurface);
        }
    }

    vec3 fullShadow = shadow * NoL;
    
    #ifdef OVERWORLD
    float rainFactor = 1.0 - rainStrength * 0.8;

    vec3 sceneLighting = mix(ambientCol, lightCol, fullShadow * rainFactor * shadowFade) * lightmap.y * lightmap.y;
    sceneLighting *= 1.0 + scattering * shadow;
    #endif

    #ifdef END
    vec3 sceneLighting = mix(endAmbientCol, endLightCol, fullShadow) * 0.25;
    #endif
    #endif

    #ifdef NETHER
    vec3 sceneLighting = pow(netherColSqrt, vec3(0.5)) * 0.125;
    #endif

    #ifdef VANILLA_AO
    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao, (1.0 - ao) * (1.0 - blockLightMap) * int(emission == 0.0) * 0.5);
    #endif

    albedo = pow(albedo, vec3(2.2));
    albedo *= sceneLighting + blockLighting + (albedo * emission * 2.0) + nightVision * 0.25 + (minLightCol * (1.0 - lightmap.y));
    albedo *= vanillaDiffuse;
    albedo = sqrt(max(albedo, vec3(0.0)));

    emission *= EMISSION_STRENGTH;

    #if defined GLOBAL_ILLUMINATION && !defined GBUFFERS_WATER
    float giVisibility = length(fullShadow * rainFactor * sunVisibility) * int(emission == 0.0);

    if (giVisibility != 0.0) {
        emission += mix(0.0, GLOBAL_ILLUMINATION_STRENGTH, giVisibility);
    }
    #endif
}