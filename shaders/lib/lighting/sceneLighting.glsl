#ifdef GBUFFERS_TERRAIN
void getSceneLighting(inout vec3 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, in vec2 lightmap,
                      in float NoU, in float NoL, in float NoE, inout float emission, in float leaves, in float foliage, in float specular, inout float coloredLightingIntensity) {
#else
void getSceneLighting(inout vec3 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, in vec2 lightmap,
                      in float NoU, in float NoL, in float NoE, inout float emission, in float leaves, in float foliage, in float specular) {
#endif
    //Variables
    float lViewPos = length(viewPos);
    float ao = color.a * color.a;

    //Vanilla Directional Lighting
	float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;

    //Block Lighting
    /*
    #ifdef GBUFFERS_TERRAIN
    float lightmapOut = lightmap.x;
    mat3 tbn = mat3(
        tangent.x, binormal.x, normal.x,
        tangent.y, binormal.y, normal.y,
        tangent.z, binormal.z, normal.z
    );
    vec3 dFdViewposX = dFdx(viewPos);
    vec3 dFdViewposY = dFdy(viewPos);
    vec2 dFdTorch = vec2(dFdx(lightmap.x), dFdy(lightmap.x));
    vec3 torchLightDir = dFdViewposX * dFdTorch.x + dFdViewposY * dFdTorch.y;
    if(length(dFdTorch) > 1e-6) {
        lightmapOut *= clamp(dot(normalize(torchLightDir), normal) + 0.8, 0.0, 1.0) * 0.5 + 0.5;
    }
    else {
        lightmapOut *= clamp(dot(tbn * vec3(0.0, 0.0, 1.0), normal), 0.0, 1.0);
    }

    lightmapOut = clamp(lightmapOut, 0.0, 0.95);
    #endif
    */

    float blockLightMap = (pow5(lightmap.x) * 1.4 + pow2(lightmap.x) * 0.6) * int(emission == 0.0);
    /*
    #ifdef GBUFFERS_TERRAIN
    blockLightMap = pow4(lightmapOut);
    #endif
    */
    vec3 blockLighting = blockLightCol * blockLightMap;

    //Colored Block Lighting & Global Illumination
    #if !defined GBUFFERS_WATER
    #if defined COLORED_LIGHTING || defined GLOBAL_ILLUMINATION
    vec3 coloredLighting = vec3(0.0);
    vec3 globalIllumination = vec3(0.0);

    float giLightMap = clamp((1.0 - pow4(lightmap.y) * 0.85) - blockLightMap, 0.0, 1.0) * int(NoU < 1.0 && leaves < 0.1 && foliage < 0.1) * 0.25 * GLOBAL_ILLUMINATION_STRENGTH * float(normal != upVec);

    applyCLGI(blockLightCol, screenPos, coloredLighting, globalIllumination, giLightMap);
    #endif

    #ifdef COLORED_LIGHTING
    blockLighting = coloredLighting * blockLightMap;
    #endif

    #ifdef GLOBAL_ILLUMINATION
    ambientCol += globalIllumination * giLightMap * (1.0 - NoL) * (1.0 - NoU) * (1.0 - rainStrength) * sunVisibility * int(emission == 0.0) * int(leaves + foliage == 0.0);
    #endif
    #endif

    //Dynamic Hand Lighting
    #ifdef DYNAMIC_HANDLIGHT
    getHandLightColor(blockLighting, lViewPos);
    #endif

    //Main Scene Lighting (Sunlight & Shadows)
    #if defined OVERWORLD || defined END
    vec3 shadow = vec3(0.0);
    float subsurface = 0.0;

    //Subsurface Scattering & Specular Highlight
    specular *= clamp(NoU - 0.01, 0.0, 1.0);

    #ifdef OVERWORLD
    if (lViewPos < shadowDistance) subsurface = leaves + foliage;

    //Subsurface Scattering & Specular Highlight
    float VoL = dot(normalize(viewPos), lightVec);
	float glareDisk = clamp(VoL * 0.5 + 0.5, 0.0, 1.0);
		  glareDisk = 0.02 / (1.0 - 0.98 * glareDisk) - 0.02;
          glareDisk *= glareDisk;
    float subsurfaceScattering = mix(mix(0.0, 2.0, glareDisk), 4.0, glareDisk * glareDisk) * subsurface;
    float specularHighlight = mix(mix(0.0, 4.0, glareDisk), 8.0, glareDisk * glareDisk) * (0.5 + specular) * (1.0 - subsurface);
    float scattering = subsurfaceScattering + specularHighlight;

    #ifndef GBUFFERS_WATER
    NoL = mix(NoL, 1.0, subsurface * (0.5 + min(scattering * 0.5, 0.5)));
    lightCol *= 1.0 + scattering;
    #endif
    #endif

    if (NoL > 0.0001) {
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
              offset *= 1.0 + subsurface * 3.0 * viewDistance;

        shadow = computeShadow(shadowPos, offset, lightmap.y, ao, subsurface, viewDistance);
    }

    vec3 fullShadow = shadow * NoL;
    
    #ifdef OVERWORLD
    float rainFactor = 1.0 - rainStrength * 0.75;

    vec3 sceneLighting = mix(ambientCol, lightCol, fullShadow * rainFactor * shadowFade) * lightmap.y;
         sceneLighting *= 1.0 + scattering * shadow;
    #endif

    #ifdef END
    vec3 sceneLighting = mix(endAmbientCol, endLightCol, fullShadow) * 0.25;
    #endif
    #endif

    #ifdef NETHER
    vec3 sceneLighting = pow(netherColSqrt, vec3(0.5)) * 0.1;
    #endif

    #ifdef VANILLA_AO
    float aoMixer = (1.0 - pow4(color.a)) * int(emission == 0.0);

    #if !defined GBUFFERS_WATER
    #ifdef GLOBAL_ILLUMINATION
    aoMixer *= clamp(1.0 - pow8(length(globalIllumination)), 0.0, 1.0);
    #endif
    #endif

    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao, aoMixer * AO_STRENGTH);
    #endif

    albedo = pow(albedo, vec3(2.2));
    albedo *= sceneLighting + blockLighting + (albedo * emission * 4.0) + nightVision * 0.25 + (minLightCol * (1.0 - lightmap.y));
    albedo *= vanillaDiffuse;
    albedo = sqrt(max(albedo, vec3(0.0)));

    emission *= EMISSION_STRENGTH;

    #if defined GBUFFERS_TERRAIN && defined GLOBAL_ILLUMINATION
    float giVisibility = clamp(length(fullShadow * (1.0 - rainStrength) * sunVisibility), 0.0, 1.0) * int(emission == 0.0 && specular == 0.0);

    if (giVisibility != 0.0) {
        coloredLightingIntensity = mix(0.0, 0.075, giVisibility);
    }
    #endif
}