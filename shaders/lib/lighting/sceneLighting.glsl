#if defined OVERWORLD || defined END
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
vec3 lightVec = sunVec;
#endif

#if defined BLOOM_COLORED_LIGHTING || defined GLOBAL_ILLUMINATION
uniform sampler2D gaux4;

float getLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}
#endif

#ifdef SHIMMER_MOD_SUPPORT
#include "/lib/lighting/shimmerModSupport.glsl"
#endif
#ifndef GBUFFERS_TERRAIN
void getSceneLighting(inout vec3 albedo, in vec3 viewPos, in vec3 worldPos, in vec3 normal, in vec2 lightmap, in float emission, in float leaves, in float foliage, in float specular) {
#else
void getSceneLighting(inout vec3 albedo, in vec3 viewPos, in vec3 worldPos, in vec3 normal, in vec2 lightmap, inout float emission, in float leaves, in float foliage, in float specular) {
#endif
    #ifdef GBUFFERS_TERRAIN
	if (foliage > 0.5){
		normal = upVec;
	}
    #endif

	float NoL = clamp(dot(normal, lightVec), 0.0, 1.0);
	float NoU = clamp(dot(normal, upVec), -1.0, 1.0);
	float NoE = clamp(dot(normal, eastVec), -1.0, 1.0);

    //Vanilla Directional Lighting
	float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
		  vanillaDiffuse*= vanillaDiffuse;

    //Block Lighting//
    vec3 blockLighting = vec3(0.0);

    #ifdef SHIMMER_MOD_SUPPORT
    float blockLightMap = (pow4(lightmap.x) * 2.0 + pow2(lightmap.x) * 0.125) * float(emission == 0.0);
    #else
    float blockLightMap = min(pow4(lightmap.x), 1.0) * float(emission == 0.0);
    #endif

    #if defined BLOOM_COLORED_LIGHTING || defined GLOBAL_ILLUMINATION
        vec3 bloom = texture2D(gaux4, gl_FragCoord.xy / vec2(viewWidth, viewHeight)).rgb;
             bloom = pow8(bloom) * 256.0;
    #endif

    if (blockLightMap > 0.0) {
        #if defined SHIMMER_MOD_SUPPORT
        //COLORED LIGHTING USING SHIMMER MOD
        vec3 coloredLight = getColoredLighting(worldPos, blockLightMap);
        blockLighting = blockLightCol * blockLightMap + coloredLight * BLOCKLIGHT_I;
        #elif defined BLOOM_COLORED_LIGHTING
        //BLOOM BASED COLORED LIGHTING
        blockLighting = blockLightCol * blockLightMap * (vec3(1.0) + clamp(bloom * pow(getLuminance(bloom) + 0.0025, -0.75), 0.0, 1.0) * clamp((pow2(blockLightMap) * 32.0) * 0.9 + 0.1, 0.0, 1.0)) * float(emission == 0.0);
        #else
        blockLighting = blockLightCol * blockLightMap;
        #endif
    }

    //Main Scene Lighting (Sunlight & Shadows)
    #if defined OVERWORLD || defined END
    specular *= clamp(NoU, 0.0, 1.0);

    float subsurface = leaves + foliage;
    float scattering = 0.0;

    vec3 shadow = vec3(0.0);

    //Subsurface Scattering & Specular Highlight
    if (subsurface > 0.0 || specular > 0.0) {
        float VoL = clamp(dot(normalize(viewPos), lightVec), 0.0, 1.0);
        VoL = pow16(VoL) + pow32(VoL);
        scattering = VoL * subsurface + VoL * specular * 2.0;
        NoL = mix(NoL, 1.0, subsurface * 0.5);
        NoL = mix(NoL, 1.0, scattering);
    }

    if (NoL > 0.0 && emission < 0.001) {
         //Shadows without peter-panning from Emin's Complementary Reimagined shaderpack, tysm for allowing me to use them ^^
        //Developed by Emin#7309 and gri573#7741
        #ifdef TAA
        float dither = clamp(fract(Bayer64(gl_FragCoord.xy) + frameTimeCounter * 16.0) / 16.0, 0.0, 1.0);
        #else
        float dither = 0.0;
        #endif

        float shadowLength = shadowDistance * 0.9166667 - length(vec4(worldPos.x, worldPos.y, worldPos.y, worldPos.z));

        if (shadowLength > 0.000001) {
            const float offset = 0.0009765;

            vec3 worldPosM = worldPos;
            vec3 worldNormal = normalize(ToWorld(normal * 1000.0));

            //Shadow bias without peter-panning
            vec3 bias = worldNormal * min(0.12 + length(worldPos) / 200.0, 0.5) * (2.0 - max(NoL, 0.0));

            //Fix light leaking in caves
            vec3 edgeFactor = 0.2 * (0.5 - fract(worldPosM + cameraPosition + worldNormal * 0.01));
            #ifndef GBUFFERS_TEXTURED
                if (lightmap.y < 0.999) worldPosM += (1.0 - pow4(max(color.a, lightmap.y))) * edgeFactor;
                #ifdef GBUFFERS_WATER
                    worldPosM += (1.0 - lightmap.y) * edgeFactor;
                #endif
            #else
                vec3 centerWorldPos = floor(worldPosM + cameraPosition) - cameraPosition + 0.5;
                worldPosM = mix(centerWorldPos, worldPosM, lightmap.y);
            #endif

            worldPosM += bias;
            vec3 shadowPos = calculateShadowPos(worldPosM);

            if (foliage > 0.5) {
                shadowPos.z += 0.00015;
            } else if (leaves > 0.5) {
                shadowPos.z -= 0.00025;
            }

            shadow = getShadow(shadowPos, dither);
        }
    }

    vec3 fullShadow = shadow * NoL;
    
    #ifdef OVERWORLD
    float rainFactor = 1.0 - rainStrength * 0.75;

    #ifdef GLOBAL_ILLUMINATION
    bloom = clamp(bloom * pow(getLuminance(bloom) + 0.001, -0.8), 0.0, 1.0) * 2.0;
    ambientCol *= vec3(1.0) + bloom * sunVisibility * (1.0 - rainStrength);
    #endif

    vec3 sceneLighting = mix(ambientCol, lightCol, fullShadow * rainFactor) * lightmap.y;
    sceneLighting *= 1.0 + scattering * shadow;
    #endif

    #ifdef END
    vec3 sceneLighting = mix(endAmbientCol, endLightCol, fullShadow) * 0.25;
    #endif
    #endif

    #ifdef NETHER
    vec3 sceneLighting = pow(netherColSqrt, vec3(0.25)) * 0.125;
    #endif

    //Minimum & Emissive Lighting//
    vec3 minLighting = minLightCol * (1.0 - lightmap.y);
    vec3 emissiveLighting = albedo * emission;

    albedo = pow(albedo, vec3(2.2));

    albedo *= sceneLighting + blockLighting + emissiveLighting + nightVision * 0.25 + minLighting;
    albedo *= vanillaDiffuse;

    albedo = sqrt(max(albedo, vec3(0.0)));

    #if defined GBUFFERS_TERRAIN && defined GLOBAL_ILLUMINATION
    emission += length(mix(vec3(0.0), vec3(GLOBAL_ILLUMINATION_STRENGTH), fullShadow)) * float(length(worldPos.xz) != 1.0) * sunVisibility * (1.0 - rainStrength);
    #endif
}