uniform vec4 lightningBoltPosition;

float lightningFlashEffect(vec3 worldPos, vec3 lightningBoltPosition, float lightDistance){ //Thanks to Xonk!
    vec3 worldNormal = ToWorld(normal);
    vec3 lightningPos = worldPos - vec3(lightningBoltPosition.x, max(worldPos.y, lightningBoltPosition.y), lightningBoltPosition.z);

    float lightningLight = max(1.0 - length(lightningPos) / lightDistance, 0.0);
          lightningLight = exp(-24.0 * (1.0 - lightningLight));

    return lightningLight * clamp(dot(-lightningPos, worldNormal), 0.0, 1.0);
}

#ifdef GBUFFERS_TERRAIN
void getSceneLighting(inout vec3 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, inout vec3 shadow, in vec2 lightmap,
                      in float NoU, in float NoL, in float NoE, inout float emission, in float foliage, in float leaves, in float subsurface, in float specular, in float parallaxShadow, inout float coloredLightingIntensity) {
#else
void getSceneLighting(inout vec3 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, inout vec3 shadow, in vec2 lightmap,
                      in float NoU, in float NoL, in float NoE, inout float emission, in float foliage, in float specular) {
#endif
    float lViewPos = length(viewPos);

    vec3 specularHighlight = vec3(0.0);

    //Vanilla AO
    float ao = color.a * color.a;

    //Vanilla Directional Lighting
	float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
          vanillaDiffuse *= vanillaDiffuse;

    #ifdef GBUFFERS_TERRAIN
    if (subsurface < 0.5) {
        NoL = pow(NoL, 1.25);
    }
    #endif

    //Block Lighting
	float blockLightMap = pow8(lightmap.x * lightmap.x) * 3.0 + max(lightmap.x - 0.05, 0.0) * 0.5;
          blockLightMap *= blockLightMap;

    #ifdef NETHER
          blockLightMap = pow6(lightmap.x) * 3.0;
    #endif

    //Block Lighting
    vec3 blockLighting = blockLightCol * blockLightMap;

    //Colored lighting & GI
    vec3 globalIllumination = vec3(0.0);
    
    #if !defined GBUFFERS_WATER
    #if defined COLORED_LIGHTING || defined GI
    applyCLGI(blockLightCol, screenPos, blockLighting, globalIllumination, blockLightMap);
    #endif
    #endif

    //Dynamic Hand Lighting
    #ifdef DYNAMIC_HANDLIGHT
    getHandLightColor(blockLighting, normal, cameraPosition, lViewPos);
    #endif

    #if defined OVERWORLD || defined END
    float scattering = 0.0;
    
    //Subsurface scattering
    #if defined OVERWORLD && defined GBUFFERS_TERRAIN
    float VoL = dot(normalize(viewPos), lightVec) * 0.5 + 0.5;
    scattering = pow16(VoL) * (1.0 - wetness * 0.75) * subsurface * shadowFade;
    if (leaves < 0.5) {
        NoL = mix(NoL, NoL + 0.25, subsurface * 0.5);
        NoL = mix(NoL, 1.0, scattering * 0.75);
    } else {
        NoL = mix(NoL, 0.6, 0.5);
        NoL = mix(NoL, 0.9, scattering * 0.5);
    }
    #endif

    //Main shadow calculation
    //Shadows without peter-panning from Emin's Complementary Reimagined shaderpack, tysm for allowing me to use them ^^
    //Developed by Emin#7309 and gri573#7741
    float shadowLength = shadowDistance * 0.9166667 - length(vec4(worldPos.x, worldPos.y, worldPos.y, worldPos.z));
    float shadow0 = 0.0;

    #ifdef GBUFFERS_WATER
    shadowLength = 1.0;
    #endif

    #ifndef SHADOWS
    shadowLength *= 0.0;
    #endif

    if (NoL > 0.0001 && shadowLength > 0.0) {
        vec3 worldNormal = normalize(ToWorld(normal * 100000.0));
        vec3 worldPosM = worldPos;

        #ifndef GBUFFERS_TEXTURED
            //Shadow bias without peter-panning
            vec3 bias = worldNormal * min(0.1 + length(worldPos) / 250.0, 0.75);
                
            //Light leaking fix from Complementary
            vec3 edgeFactor = 0.25 * (0.5 - fract(worldPosM + cameraPosition + worldNormal * 0.01));

            worldPosM += (1.0 - ao) * edgeFactor;
            worldPosM += bias;
        #else
            vec3 centerWorldPos = floor(worldPosM + cameraPosition) - cameraPosition + 0.5;
            worldPosM = mix(centerWorldPos, worldPosM + vec3(0.0, 0.02, 0.0), lightmap.y);
        #endif

        vec3 shadowPos = ToShadow(worldPosM);

        float viewDistance = 1.0 - clamp(lViewPos * 0.01, 0.0, 1.0);
        float offset = mix(0.00125, 0.00125 * ao, (1.0 - ao));
        #if defined GBUFFERS_TERRAIN
              offset *= 1.0 + subsurface * 2.0 * viewDistance;
        #endif

        #ifndef GBUFFERS_TERRAIN
        float subsurface = 0.0;
        #endif

        shadow = computeShadow(shadowPos, offset, ao, lightmap.y, subsurface, viewDistance, shadow0);
    } else {
        shadow = getFakeShadow(lightmap.y);
    }

    #if defined PBR && defined GBUFFERS_TERRAIN
    shadow *= parallaxShadow;
    #endif

    NoL = clamp(NoL * 1.01 - 0.01, 0.0, 1.0);

    vec3 fullShadow = shadow * NoL * lightmap.y;

    #ifdef OVERWORLD
    float rainFactor = 1.0 - wetness * 0.75;

    vec3 newAmbientCol = ambientCol;

    #ifdef GI
    #ifdef GBUFFERS_TERRAIN
    float NoN = clamp(abs(dot(normal, northVec)) + clamp(1.0 - NoU, 0.0, 1.0), 0.0, 1.0);
    globalIllumination *= 0.75 * NoN + 0.25;
    #endif

    newAmbientCol += globalIllumination * GLOBAL_ILLUMINATION_BRIGHTNESS * sunVisibility * lightmap.y;
    #endif

    vec3 sceneLighting = mix(newAmbientCol, lightCol, fullShadow * rainFactor * shadowFade) * lightmap.y * lightmap.y;
         sceneLighting *= 1.0 + scattering * shadow;
    #endif

    #ifdef END
    vec3 sceneLighting = mix(endAmbientCol, endLightCol, fullShadow) * 0.2;
    #endif
    #endif

    #ifdef NETHER
    vec3 sceneLighting = pow(netherColSqrt, vec3(0.5)) * 0.1;
    #endif

    //Vanilla AO
    #ifdef VANILLA_AO
    float aoMixer = (1.0 - pow2(color.a)) * int(emission == 0.0);

    aoMixer *= 1.0 - min(blockLightMap, 1.0);

    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao * ao, aoMixer * AO_STRENGTH);
    #endif

    //Iris lightning flash, made by Xonk
    #if defined IS_IRIS && !defined GBUFFERS_WATER
    sceneLighting += lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 196.0) * lightningBoltPosition.w * 2.0;
    #endif

    //Specular highlight
    #if defined GBUFFERS_TERRAIN && defined OVERWORLD
	vec3 baseReflectance = vec3(0.04);

    #ifndef PBR
	float smoothness = mix(clamp(length(albedo.rgb) * 0.4 + NoL * 0.1, 0.1, 0.7), 1.0, specular);
    #else
    float smoothness = specular * 1.25;
    if (smoothness == 0.0) {
        smoothness = mix(clamp(length(albedo.rgb) * 0.4 + NoL * 0.1, 0.1, 0.7), 1.0, specular);
    }
    #endif

    smoothness = clamp(smoothness, 0.0, 0.9);

	specularHighlight = GetSpecularHighlight(normal, viewPos, smoothness, baseReflectance, lightCol, shadow * vanillaDiffuse, color.a);
    specularHighlight = clamp(specularHighlight * lightmap.y, vec3(0.0), vec3(1.0));
    #endif

    //Emission
    sceneLighting += albedo.rgb * emission * 2.0;

    //Night vision
    sceneLighting += nightVision * 0.25;

    //Cave lighting (no skylight)
    sceneLighting += minLightCol * (1.0 - lightmap.y);

    //Blocklighting
    sceneLighting += blockLighting * int(emission == 0.0);

    albedo = pow(albedo, vec3(2.2));
    albedo *= sceneLighting;
    albedo *= vanillaDiffuse;
    albedo += specularHighlight;
    albedo = sqrt(max(albedo, vec3(0.0)));

    emission *= EMISSION_STRENGTH;

    #ifdef GI
    #ifdef GBUFFERS_TERRAIN
    float giVisibility = shadow0 * rainFactor * sunVisibility * int(emission == 0.0);

    coloredLightingIntensity += 0.0145 * giVisibility;
    #endif
    #endif
}