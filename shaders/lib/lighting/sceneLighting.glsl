#ifdef OVERWORLD
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
vec3 lightVec = sunVec;
#endif

#ifdef BLOOM_COLORED_LIGHTING
void computeBCL(inout vec3 blockLighting, in vec3 bloom, in vec2 lightmap, in float blockLightMap) {
	bloom = clamp(0.01 * bloom * pow(getLuminance(bloom), -COLORED_LIGHTING_RADIUS), 0.0, 1.0) * 100.0;

    blockLighting += bloom * COLORED_LIGHTING_STRENGTH * blockLightMap;
}
#endif

#if defined GBUFFERS_TERRAIN || defined GBUFFERS_WATER
void getSceneLighting(inout vec3 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, in vec2 lightmap,
                      in float NoU, in float NoL, in float NoE, inout float emission, inout float coloredLightingIntensity, in float leaves, in float foliage, in float specular) {
#else
void getSceneLighting(inout vec3 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, in vec2 lightmap,
                      in float NoU, in float NoL, in float NoE, in float emission, in float leaves, in float foliage, in float specular) {
#endif
    lightmap.y *= lightmap.y;

    //Variables
    float lViewPos = length(viewPos);
    float ao = color.a * color.a;

    //Vanilla Directional Lighting
	float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;

    //Block Lighting//
    float blockLightMap = clamp(pow8(lightmap.x) * 0.75 + pow4(lightmap.x) * 0.25 + lightmap.x * lightmap.x * 0.125, 0.0, 1.0) * int(emission == 0.0);
    vec3 blockLighting = blockLightCol * blockLightMap;

    //Bloom Colored Lighting
    #ifdef BLOOM_COLORED_LIGHTING
    vec3 bloom = texture2D(gaux1, screenPos.xy).rgb;
         bloom = pow4(bloom) * 128.0;

    if (emission == 0.0) computeBCL(blockLighting, bloom, lightmap, blockLightMap);
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
    #ifdef OVERWORLD
    if (lViewPos < shadowDistance + 32.0) subsurface = leaves + foliage;

    //Subsurface Scattering & Specular Highlight
    float VoL = dot(normalize(viewPos), lightVec);
	float glareDisk = clamp(VoL * 0.5 + 0.5, 0.0, 1.0);
		  glareDisk = 0.03 / (1.0 - 0.97 * glareDisk) - 0.03;
    float scattering = mix(mix(0.0, 1.0, glareDisk), 2.0, pow3(glareDisk));

    #ifndef GBUFFERS_WATER
    NoL = mix(NoL, 1.0, subsurface * (0.5 + min(scattering * 0.5, 0.5)));
    lightCol *= 1.0 + scattering;
    #endif
    #endif

    if (NoL > 0.0001) {
        //Shadows without peter-panning from Emin's Complementary Reimagined shaderpack, tysm for allowing me to use them ^^
        //Developed by Emin#7309 and gri573#7741
        #ifdef TAA
        float dither = fract(Bayer64(gl_FragCoord.xy) + frameTimeCounter * 16.0) * TAU * (1.0 - subsurface * 0.5);
        #else
        float dither = 0.0;
        #endif

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

        if (lViewPos < shadowDistance + 32.0) {
            if (leaves > 0.5) shadowPos.z -= 0.0005;
            else if (foliage > 0.5) shadowPos.z += 0.000125;
        }

        float viewDistance = 1.0 - clamp(lViewPos * 0.01, 0.0, 1.0);
        float offset = mix(0.0009765, 0.0009765 * ao, (1.0 - ao));
              offset *= 1.0 + subsurface * 4.0 * viewDistance;

        shadow = computeShadow(shadowPos, offset, dither, lightmap.y, ao, subsurface, viewDistance);
    }

    vec3 fullShadow = shadow * NoL;
    
    #ifdef OVERWORLD
    float rainFactor = 1.0 - rainStrength * 0.75;

    vec3 sceneLighting = mix(ambientCol, mix(lightCol, lightColSqrt, timeBrightnessSqrt), fullShadow * rainFactor * shadowFade) * lightmap.y;
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
    float aoMixer = (1.0 - pow4(color.a)) * int(emission == 0.0);

    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao, aoMixer * AO_STRENGTH);
    #endif

    albedo = pow(albedo, vec3(2.2));
    albedo *= sceneLighting + blockLighting + (albedo * emission * 2.0) + nightVision * 0.25 + (minLightCol * (1.0 - lightmap.y));
    albedo *= vanillaDiffuse;
    albedo = sqrt(max(albedo, vec3(0.0)));

    emission *= EMISSION_STRENGTH;

    #ifdef BCL_GLASS_LIGHT_RECOLORING
    if (mat == 3) {
        coloredLightingIntensity = pow4(lightmap.x) * 9.0;
        albedo.rgb *= 1.0 + pow4(lightmap.x);
    }
    #endif

    #if defined SSGI && defined GBUFFERS_TERRAIN
    coloredLightingIntensity = mix(coloredLightingIntensity, 0.17, float(length(fullShadow) > 0.0));
    #endif
}