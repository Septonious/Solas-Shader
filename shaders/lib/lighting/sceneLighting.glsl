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
                      in float NoU, in float NoL, in float NoE, inout float emission, in float leaves, in float foliage, in float specular, inout float coloredLightingIntensity) {
#else
void getSceneLighting(inout vec3 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, inout vec3 shadow, in vec2 lightmap,
                      in float NoU, in float NoL, in float NoE, inout float emission, in float leaves, in float foliage, in float specular) {
#endif
    float lViewPos = length(viewPos);
    float subsurface = leaves + foliage;

    //Vanilla AO
    float ao = color.a * color.a;

    #ifdef VANILLA_AO
    float aoMixer = (1.0 - pow2(color.a)) * int(emission == 0.0);

    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao * ao, aoMixer * AO_STRENGTH);
    #endif

    //Vanilla Directional Lighting
	float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
          vanillaDiffuse *= vanillaDiffuse;

    //Block Lighting
	float blockLightMap = pow6(lightmap.x * lightmap.x) * 3.0 + max(lightmap.x - 0.05, 0.0);
          blockLightMap *= blockLightMap * 0.5;
    #ifdef OVERWORLD
          blockLightMap *= 1.0 - lightmap.y * 0.5 * timeBrightness;
    #endif

    #ifdef NETHER
          blockLightMap = pow6(lightmap.x) * 3.0;
    #endif

    #if defined GBUFFERS_TERRAIN && defined COLORED_LIGHTING
    mat3 tbn = mat3(
        tangent.x, binormal.x, normal.x,
        tangent.y, binormal.y, normal.y,
        tangent.z, binormal.z, normal.z
    );

    vec3 dFdViewposX = dFdx(viewPos);
    vec3 dFdViewposY = dFdy(viewPos);
    vec2 dFdTorch = vec2(dFdx(pow4(lightmap.x) * 4.0), dFdy(pow4(lightmap.x) * 4.0));
    vec3 torchLightDir = dFdViewposX * dFdTorch.x + dFdViewposY * dFdTorch.y;

    if (length(dFdTorch) > 1e-6 && foliage < 0.5) {
        blockLightMap *= clamp(dot(normalize(torchLightDir), normal) + 0.9, 0.0, 1.0) * 0.5 + 0.5;
    }
    #endif

    //Block Lighting
    vec3 blockLighting = blockLightCol * blockLightMap;

    //Colored lighting & GI
    vec3 coloredLighting = vec3(0.0);
    vec3 globalIllumination = vec3(0.0);
    
    #if !defined GBUFFERS_WATER
    #if defined COLORED_LIGHTING || defined GI
    applyCLGI(blockLightCol, screenPos, blockLighting, globalIllumination, blockLightMap);
    #endif

    #ifdef GI
    globalIllumination *= 1.0 - NoL * 0.5;
    globalIllumination *= 1.0 - NoU * 0.5;
    globalIllumination *= 1.0 - pow8(lightmap.y) * 0.5;
    globalIllumination *= 1.0 - blockLightMap;
    #endif
    #endif

    //Dynamic Hand Lighting
    #ifdef DYNAMIC_HANDLIGHT
    getHandLightColor(blockLighting, normal, cameraPosition, lViewPos);
    #endif

    #if defined OVERWORLD || defined END
    //Subsurface scattering
    #ifdef OVERWORLD
    float VoL = dot(normalize(viewPos), lightVec) * 0.5 + 0.5;
    float scattering = pow16(VoL) * (1.0 - wetness * 0.75) * subsurface * shadowFade;
    NoL = mix(NoL, 1.0, subsurface * 0.75);
    NoL = mix(NoL, 1.0, scattering);
    #endif

    //Main shadow calculation
    //Shadows without peter-panning from Emin's Complementary Reimagined shaderpack, tysm for allowing me to use them ^^
    //Developed by Emin#7309 and gri573#7741
    float shadowLength = shadowDistance * 0.9166667 - length(vec4(worldPos.x, worldPos.y, worldPos.y, worldPos.z));

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
              offset *= 1.0 + subsurface * 2.0 * viewDistance;

        shadow = computeShadow(shadowPos, offset, lightmap.y, ao, subsurface, viewDistance);
    } else {
        shadow = getFakeShadow(lightmap.y);
    }

    NoL = clamp(NoL * 1.01 - 0.01, 0.0, 1.0);

    vec3 fullShadow = shadow * NoL * lightmap.y;
    
    #ifdef OVERWORLD
    float rainFactor = 1.0 - wetness * 0.75;

    vec3 newAmbientCol = ambientCol;

    #ifdef GI
    ambientCol += globalIllumination * 0.5;
    #endif

    vec3 sceneLighting = mix(ambientCol, lightCol, fullShadow * rainFactor * shadowFade) * lightmap.y;
         sceneLighting *= 1.0 + scattering * shadow;

    //Specular highlight
    #ifdef GBUFFERS_TERRAIN
	vec3 baseReflectance = vec3(0.1);
	float smoothness = mix(0.4, 0.9, clamp(specular * 2.0, 0.0, 1.0));
		 sceneLighting += GetSpecularHighlight(normal, viewPos, smoothness, baseReflectance,
										   	   lightCol, shadow * vanillaDiffuse, color.a);
    #endif
    #endif

    #ifdef END
    vec3 sceneLighting = mix(endAmbientCol, endLightCol, fullShadow) * 0.2;
    #endif
    #endif

    #ifdef NETHER
    vec3 sceneLighting = pow(netherColSqrt, vec3(0.5)) * 0.1;
    #endif

    //Iris lightning flash, made by Xonk
    #if defined IS_IRIS && !defined GBUFFERS_WATER
    sceneLighting += lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 196.0) * lightningBoltPosition.w * 2.0;
    #endif

    //Emission
    sceneLighting += albedo.rgb * emission * 4.0;

    //Night vision
    sceneLighting += nightVision * 0.25;

    //Cave lighting (no skylight)
    sceneLighting += minLightCol * (1.0 - lightmap.y);

    //Blocklighting
    sceneLighting += blockLighting * int(emission == 0.0);

    albedo = pow(albedo, vec3(2.2));
    albedo *= sceneLighting;
    albedo *= vanillaDiffuse;
    albedo = sqrt(max(albedo, vec3(0.0)));

    emission *= EMISSION_STRENGTH;

    #ifdef GI
    #ifdef GBUFFERS_TERRAIN
    float giVisibility = length(fullShadow * rainFactor * shadowFade * sunVisibility) * int(emission == 0.0) * int(subsurface == 0.0) * int(specular == 0.0);

    if (giVisibility != 0.0) {
        coloredLightingIntensity = mix(coloredLightingIntensity, 0.095, giVisibility);
    }
    #endif
    #endif
}