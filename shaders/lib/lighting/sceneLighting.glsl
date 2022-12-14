#if defined OVERWORLD || defined END
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
vec3 lightVec = sunVec;
#endif

#ifdef BLOOM_COLORED_LIGHTING
void computeBCL(inout vec3 blockLighting, in vec3 bloom, in float lViewPos, in float directionalBloom, in float blockLightMap, in float skyLightMap) {
    float bloomLightMap = blockLightMap * blockLightMap * 1.25 + blockLightMap * 0.5 + 0.25;

	vec3 coloredLight = clamp(0.0625 * bloom * pow(getLuminance(bloom), COLORED_LIGHTING_RADIUS), 0.0, 1.0) * 32.0; //16.0 * 2.0 for higher visibility
    
    blockLighting += coloredLight * bloomLightMap * directionalBloom;
}
#endif

#if defined GBUFFERS_TERRAIN || defined GBUFFERS_WATER
void getSceneLighting(inout vec3 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, in vec2 lightmap,
                      in float NoU, in float NoL, in float NoE, inout float emission, inout float coloredLightingIntensity, in float leaves, in float foliage, in float specular) {
#else
void getSceneLighting(inout vec3 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, in vec2 lightmap,
                      in float NoU, in float NoL, in float NoE, in float emission, in float leaves, in float foliage, in float specular) {
#endif
    //Variables
    float lViewPos = length(viewPos);
    float ao = color.a * color.a;

    //Vanilla Directional Lighting
	float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;

    //Block Lighting//
    float blockLightMap = min(pow8(lightmap.x) + pow4(lightmap.x) * 0.5, 1.0) * int(emission == 0.0);

    vec3 worldNormal = normalize(ToWorld(normal * 10000.0));
    vec3 worldNormalGMVI = normalize(ToWorld(mat3(gbufferModelViewInverse) * normal));
    vec3 blockLighting = blockLightCol * (1.0 - clamp(dot(normalize(vec3(blockLightMap)), worldNormal) - 0.15, 0.0, 1.0)) * blockLightMap;

    #if defined BLOOM_COLORED_LIGHTING || defined GLOBAL_ILLUMINATION
    vec3 bloom = texture2D(gaux1, screenPos.xy).rgb;
         bloom = pow4(bloom) * 128.0;
    float directionalBloom = 1.0 - clamp(dot(normalize(bloom), worldNormalGMVI) - 0.15, 0.0, 1.0);
    #endif

    #if defined BLOOM_COLORED_LIGHTING
    //Bloom Based Colored Lighting
    if (emission == 0.0) computeBCL(blockLighting, bloom, lViewPos, directionalBloom, lightmap.x, lightmap.y);
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
	float glareDisk = clamp(VoL * 0.5 + 0.5, 0.0, 1.0);
		  glareDisk = 0.03 / (1.0 - 0.97 * glareDisk) - 0.03;
    float scattering = mix(mix(0.0, 1.0, glareDisk), 3.0, pow2(glareDisk));

    NoL = mix(NoL, 0.5, subsurface * (0.5 + min(scattering * 0.5, 0.5)));
    lightCol *= 1.0 + scattering;
    #endif

    if (NoL > 0.0001) {
        //Shadows without peter-panning from Emin's Complementary Reimagined shaderpack, tysm for allowing me to use them ^^
        //Developed by Emin#7309 and gri573#7741
        #ifdef TAA
        float dither = fract(Bayer64(gl_FragCoord.xy) + frameTimeCounter * 16.0) * (1.0 + subsurface * 3.0) * TAU;
        #else
        float dither = 0.0;
        #endif

        float shadowLength = shadowDistance * 0.9166667 - length(vec4(worldPos.x, worldPos.y, worldPos.y, worldPos.z));

        if (shadowLength > 0.000001) {
            vec3 worldPosM = worldPos;

            #ifndef GBUFFERS_TEXTURED
                //Shadow bias without peter-panning
                vec3 bias = worldNormal * min(0.1 + length(worldPos) / 250.0, 0.75);
                
                //Light leaking fix from Complementary
                if (lightmap.y < 0.001) {
                    vec3 edgeFactor = 0.25 * (0.5 - fract(worldPosM + cameraPosition + worldNormal * 0.01));
                    worldPosM += (1.0 - ao) * edgeFactor;
                }

                worldPosM += bias;
            #else
                vec3 centerWorldPos = floor(worldPosM + cameraPosition) - cameraPosition + 0.5;
                worldPosM = mix(centerWorldPos, worldPosM + vec3(0.0, 0.02, 0.0), lightmap.y);
            #endif

            vec3 shadowPos = calculateShadowPos(worldPosM);

            #ifdef OVERWORLD
            if (leaves > 0.5) {
                shadowPos.z = mix(shadowPos.z + 0.001, shadowPos.z - 0.001, 0.5 + min(scattering * 0.5, 0.5));
            } else if (foliage > 0.5) {
                shadowPos.z += 0.000125;
            }
            #endif

            float viewLengthFactor = 1.0 - clamp(length(viewPos.xz) * 0.01, 0.0, 1.0);
            float offset = mix(shadowOffset, shadowOffset * ao, (1.0 - ao)) * (1.0 + foliage * 3.0 * viewLengthFactor);

            shadow = computeShadow(shadowPos, offset, dither, lightmap.y, ao, subsurface, viewLengthFactor);
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
    float aoMixer = (1.0 - pow3(color.a)) * (1.0 - blockLightMap) * int(emission == 0.0);

    #if defined OVERWORLD
    aoMixer *= 1.0 - min(length(fullShadow * rainFactor * sunVisibility), 1.0);
    #elif defined END
    aoMixer *= 1.0 - min(length(fullShadow), 1.0);
    #endif

    #if defined BLOOM_COLORED_LIGHTING || defined GLOBAL_ILLUMINATION
    aoMixer *= 1.0 - clamp(getLuminance(bloom), 0.0, 0.5);
    #endif

    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao, aoMixer * 0.75);
    #endif

    albedo = pow(albedo, vec3(2.2));
    albedo *= sceneLighting + blockLighting + (albedo * emission * 2.0) + nightVision * 0.25 + (minLightCol * (1.0 - lightmap.y));
    albedo *= vanillaDiffuse;
    albedo = sqrt(max(albedo, vec3(0.0)));

    emission *= EMISSION_STRENGTH;

    #if (defined GLOBAL_ILLUMINATION && defined BLOOM_COLORED_LIGHTING) || (defined SSPT && defined GLOBAL_ILLUMINATION)
    float giVisibility = length(fullShadow * rainFactor * sunVisibility) * int(emission == 0.0 && specular == 0.0);

    if (giVisibility != 0.0) {
        coloredLightingIntensity += mix(0.0, GLOBAL_ILLUMINATION_STRENGTH * (0.2 - clamp(getLuminance(albedo.rgb), 0.0, 0.15)), giVisibility);
    }
    #endif

    #ifdef GBUFFERS_WATER
    int glass = int(mat == 3);

    coloredLightingIntensity += glass * int(blockLightMap > 0.25) * 8.0;
    #endif
}