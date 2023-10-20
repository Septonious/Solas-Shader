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
    //Variables
    float lViewPos = length(viewPos);
    float ao = color.a * color.a;

    //Vanilla Directional Lighting
	float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;

    //Block Lighting
    #if defined GBUFFERS_TERRAIN && defined COLORED_LIGHTING
    float lightmapOut = clamp(pow6(lightmap.x) * 1.5 + pow3(lightmap.x) * 0.5, 0.0, 1.0);
    mat3 tbn = mat3(
        tangent.x, binormal.x, normal.x,
        tangent.y, binormal.y, normal.y,
        tangent.z, binormal.z, normal.z
    );
    vec3 dFdViewposX = dFdx(viewPos);
    vec3 dFdViewposY = dFdy(viewPos);
    vec2 dFdTorch = vec2(dFdx(lightmapOut), dFdy(lightmapOut));
    vec3 torchLightDir = dFdViewposX * dFdTorch.x + dFdViewposY * dFdTorch.y;

    if (length(dFdTorch) > 1e-6) {
        lightmapOut *= clamp(dot(normalize(torchLightDir), normal) + 0.85, 0.0, 1.0) * 0.5 + 0.5;
    }

    lightmapOut = clamp(lightmapOut, 0.0, 1.0);
    #endif

    float blockLightMap = clamp(pow6(lightmap.x) * 1.5 + pow3(lightmap.x) * 0.5, 0.0, 1.0);

    #if defined GBUFFERS_TERRAIN && defined COLORED_LIGHTING
    blockLightMap = lightmapOut;
    #endif

    vec3 blockLighting = blockLightCol * blockLightMap * int(emission == 0.0);

    //Colored Block Lighting && GI
    vec3 gi = vec3(0.0);
    
    #if !defined GBUFFERS_WATER
    #if defined COLORED_LIGHTING || defined GI
    vec3 coloredLighting = vec3(0.0);

    applyCLGI(blockLightCol, screenPos, coloredLighting, gi, lightmap);
    #endif

    #ifdef COLORED_LIGHTING
    blockLighting = coloredLighting * blockLightMap;
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

    //Main Scene Lighting (Sunlight & Shadows)
    #if defined OVERWORLD || defined END
    float subsurface = 0.0;

    //Subsurface Scattering & Specular Highlight
    specular *= clamp(NoU - 0.01, 0.0, 1.0);

    #ifdef OVERWORLD
    if (lViewPos < shadowDistance) subsurface = leaves + foliage;

    //Subsurface Scattering & Specular Highlight
    float VoL = clamp(dot(normalize(viewPos.xyz), lightVec) * 0.5 + 0.5, 0.0, 1.0);
    float scattering = pow(VoL, 16.0) * (1.0 - wetness) * subsurface * shadowFade;
    NoL = clamp(NoL * 1.01 - 0.01, 0.0, 1.0);
    NoL = mix(NoL, 1.0, subsurface * 0.75);
    NoL = mix(NoL, 1.0, scattering);
    #endif

    float shadowLength = shadowDistance * 0.9166667 - length(vec4(worldPos.x, worldPos.y, worldPos.y, worldPos.z));

    if (NoL > 0.0001 && shadowLength > 0.000001) {
        //Shadows without peter-panning from Emin's Complementary Reimagined shaderpack, tysm for allowing me to use them ^^
        //Developed by Emin#7309 and gri573#7741
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

        if (lViewPos < shadowDistance && leaves > 0.5) shadowPos.z -= 0.0005;

        float viewDistance = 1.0 - clamp(lViewPos * 0.01, 0.0, 1.0);
        float offset = mix(0.0009765, 0.0009765 * ao, (1.0 - ao));
              offset *= 1.0 + subsurface * 2.0 * viewDistance;

        shadow = computeShadow(shadowPos, offset, lightmap.y, ao, subsurface, viewDistance);
    } else {
        shadow = getFakeShadow(lightmap.y);
    }

    vec3 fullShadow = shadow * NoL;
    
    #ifdef OVERWORLD
    float rainFactor = 1.0 - wetness * 0.75;

    vec3 sceneLighting = mix(ambientCol + mix(vec3(0.0), gi, GLOBAL_ILLUMINATION_STRENGTH), lightCol, fullShadow * rainFactor * shadowFade) * lightmap.y;
         sceneLighting *= 1.0 + scattering * shadow;

    #if defined IS_IRIS && !defined GBUFFERS_WATER
    sceneLighting += lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 196.0) * lightningBoltPosition.w * 2.0;
    #endif

    #if defined GBUFFERS_TERRAIN && !defined NETHER
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

    #ifdef VANILLA_AO
    float aoMixer = (1.0 - pow4(color.a)) * int(emission == 0.0);

    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao, aoMixer * AO_STRENGTH);
    #endif

    albedo = pow(albedo, vec3(2.2));
    albedo *= sceneLighting + blockLighting + (albedo * emission * 4.0) + nightVision * 0.25 + (minLightCol * (1.0 - lightmap.y));
    albedo *= vanillaDiffuse;
    albedo = sqrt(max(albedo, vec3(0.0)));

    emission *= EMISSION_STRENGTH;

    #ifdef GI
    #ifdef GBUFFERS_TERRAIN
    float giVisibility = length(fullShadow * rainFactor * shadowFade * sunVisibility) * int(emission == 0.0);

    if (giVisibility != 0.0) {
        coloredLightingIntensity = mix(coloredLightingIntensity, 0.095, giVisibility);
    }
    #endif
    #endif
}