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

    //Vanilla AO
    float ao = color.a * color.a;

    #ifdef VANILLA_AO
    float aoMixer = (1.0 - pow4(color.a)) * int(emission == 0.0);

    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao, aoMixer * AO_STRENGTH);
    #endif

    //Vanilla Directional Lighting
	float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
		  vanillaDiffuse *= vanillaDiffuse;

    //Block Lighting
    float blockLightMap = clamp(pow6(lightmap.x) * 1.25 + pow3(lightmap.x) * 0.75, 0.0, 1.0);

    //Directional lightmap
    #if defined GBUFFERS_TERRAIN && defined COLORED_LIGHTING
    mat3 tbn = mat3(
        tangent.x, binormal.x, normal.x,
        tangent.y, binormal.y, normal.y,
        tangent.z, binormal.z, normal.z
    );

    vec3 dFdViewPosX = dFdx(viewPos);
    vec3 dFdViewPosY = dFdy(viewPos);
    vec2 dFdTorch = vec2(dFdx(blockLightMap), dFdy(blockLightMap));
    vec3 torchLightDir = dFdViewPosX * dFdTorch.x + dFdViewPosY * dFdTorch.y;

    if (length(dFdTorch) > 0.000001) {
        blockLightMap *= clamp(dot(normalize(torchLightDir), normal) + 0.85, 0.0, 1.0) * 0.5 + 0.5;
    }
    #endif

    vec3 blockLighting = blockLightCol * blockLightMap * int(emission == 0.0);

    //Colored lighting & GI
    vec3 coloredLighting = vec3(0.0);
    vec3 gi = vec3(0.0);
    
    #if !defined GBUFFERS_WATER
    #if defined COLORED_LIGHTING || defined GI
    applyCLGI(blockLightCol, screenPos, coloredLighting, gi, lightmap);
    #endif

    #ifdef COLORED_LIGHTING
    blockLighting = coloredLighting * blockLightMap * int(emission == 0.0);
    #endif

    #ifdef GI
    gi *= 1.0 - NoL * 0.5;
    gi *= 1.0 - NoU * 0.5;
    gi *= lightmap.y;
    #endif
    #endif

    //Dynamic Hand Lighting
    #ifdef DYNAMIC_HANDLIGHT
    getHandLightColor(blockLighting, normal, cameraPosition, lViewPos);
    #endif

    #if defined OVERWORLD || defined END
    //Subsurface scattering
    float subsurface = leaves + foliage;

    float VoL = dot(normalize(viewPos), lightVec) * 0.5 + 0.5;
    float scattering = pow16(VoL) * (1.0 - wetness * 0.75) * subsurface * shadowFade;
    NoL = mix(NoL, 1.0, subsurface * 0.75);
    NoL = mix(NoL, 1.0, scattering);

    //Main shadow calculation
    //Shadows without peter-panning from Emin's Complementary Reimagined shaderpack, tysm for allowing me to use them ^^
    //Developed by Emin#7309 and gri573#7741
    float shadowLength = shadowDistance * 0.9166667 - length(vec4(worldPos.x, worldPos.y, worldPos.y, worldPos.z));

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
        float offset = mix(0.0009765, 0.0009765 * ao, (1.0 - ao));

        shadow = computeShadow(shadowPos, offset, lightmap.y, ao, subsurface, viewDistance);
    } else {
        shadow = getFakeShadow(lightmap.y);
    }

    NoL = clamp(NoL * 1.01 - 0.01, 0.0, 1.0);

    vec3 fullShadow = shadow * NoL * lightmap.y;
    
    #ifdef OVERWORLD
    float rainFactor = 1.0 - wetness * 0.75;

    vec3 sceneLighting = mix(ambientCol, lightCol, fullShadow * rainFactor * shadowFade);
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

    //Block lighting
    sceneLighting += blockLighting;

    albedo = pow(albedo, vec3(2.2));
    albedo *= sceneLighting;
    albedo *= vanillaDiffuse;
    albedo = sqrt(max(albedo, vec3(0.0)));

    emission *= EMISSION_STRENGTH;
}