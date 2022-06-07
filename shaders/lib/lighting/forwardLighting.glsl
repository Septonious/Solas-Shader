#if defined OVERWORLD || defined END
#include "/lib/lighting/shadows.glsl"
#endif

#if MC_VERSION >= 11900
uniform float darknessLightFactor;
#endif

void GetLighting(inout vec3 albedo, vec3 viewPos, vec3 worldPos, vec2 lightmap, float emission, float subsurface) {
	float NoL = clamp(dot(normal, lightVec), 0.0, 1.0);
	float NoU = clamp(dot(normal, upVec), -1.0, 1.0);
	float NoE = clamp(dot(normal, eastVec), -1.0, 1.0);

	float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
		  vanillaDiffuse*= vanillaDiffuse;

    emission *= dot(albedo.rgb, albedo.rgb) * 0.333;

    float lightFlatten = clamp(1.0 - pow(1.0 - emission, 128.0), 0.0, 1.0);

    #if defined OVERWORLD || defined END
    vec3 shadow = vec3(0.0);
    if (NoL > 0.0 || subsurface > 0.0) {
        //Shadows without peter-panning from Emin's Complementary Reimagined shaderpack, tysm for allowing me to use them ^^
        float shadowLength = shadowDistance * 0.9166667 - length(vec4(worldPos.x, worldPos.y, worldPos.y, worldPos.z));

        if (shadowLength > 0.000001) {
            float offset = 0.0009765;

            vec3 worldPosM = worldPos;
            vec3 worldNormal = normalize(ToWorld(normal * 1000.0));
            //Shadow bias without peter-panning
            vec3 bias = worldNormal * min(0.12 + length(worldPos) / 200.0, 0.5) * (2.0 - max(NoL, 0.0));

            //Fix light leaking in caves
            vec3 edgeFactor = 0.2 * (0.5 - fract(worldPosM + cameraPosition + worldNormal * 0.01));
            #ifndef GBUFFERS_TEXTURED
                if (lightmap.y < 0.999) worldPosM += (1.0 - pow2(pow2(max(color.a, lightmap.y)))) * edgeFactor;
                #ifdef GBUFFERS_WATER
                    bias *= 0.5;
                    worldPosM += (1.0 - lightmap.y) * edgeFactor;
                #endif
            #else
                vec3 centerWorldPos = floor(worldPosM + cameraPosition) - cameraPosition + 0.5;
                worldPosM = mix(centerWorldPos, worldPosM, lightmap.y);
            #endif

            worldPosM += bias;
                        
            shadow = GetShadow(worldPosM, NoL);
        }
    }
    
    float scattering = 0.0;
    if (subsurface > 0.0){
        float VoL = clamp(dot(normalize(viewPos.xyz), lightVec) * 0.5 + 0.5, 0.0, 1.0);
        scattering = pow8(VoL) * subsurface;
        NoL = mix(NoL, 1.0, subsurface);
        NoL = mix(NoL, 1.0, scattering);
    }
    
    vec3 fullShadow = shadow * NoL;
    
    #ifdef OVERWORLD
    float shadowMult = (1.0 - rainStrength * 0.8) * shadowFade;
    vec3 sceneLighting = mix(ambientCol * (1.0 + subsurface * pow2(lightmap.y)) * pow2(lightmap.y), lightCol, fullShadow * shadowMult);
    sceneLighting *= 1.0 + scattering * shadow;
    #endif

    #ifdef END
    vec3 sceneLighting = endCol * (0.06 * fullShadow + 0.02);
    #endif

    #else
    vec3 sceneLighting = netherColSqrt * 0.25;
    #endif
    
    float newLightmap  = (pow8(lightmap.x) + lightmap.x * 0.75) * (1.0 - lightFlatten * 0.75);
    vec3 blockLighting = blocklightCol * clamp(newLightmap * newLightmap, 0.0, 1.0) * (1.0 - lightmap.y * 0.75);

    #ifdef SSPT
    blockLighting *= 0.1;
    #endif

    vec3 minLighting = minLightCol * (1.0 - lightmap.y);
    vec3 albedoNormalized = normalize(albedo.rgb + 0.00001);
    vec3 emissiveLighting = mix(albedoNormalized, vec3(1.0), emission * 0.5) * emission * EMISSION_STRENGTH;

    #if MC_VERSION >= 11900
    sceneLighting *= 1.0 - darknessLightFactor;
    #endif

    vanillaDiffuse = mix(vanillaDiffuse, 1.0, lightFlatten);
    
    albedo *= sceneLighting + blockLighting + emissiveLighting + nightVision * 0.25 + minLighting;
    albedo *= vanillaDiffuse;
}