uniform vec4 lightningBoltPosition;

#include "/lib/lighting/lightning.glsl"

#ifdef VC_SHADOWS
#include "/lib/lighting/cloudShadows.glsl"
#endif

void gbuffersLighting(inout vec4 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, inout vec3 shadow, in vec2 lightmap, 
                    in float NoU, in float NoL, in float NoE,
                    in float subsurface, in float smoothness, in float emission, in float parallaxShadow) {
    //Variables
    float NoLm = NoL;
    float lViewPos = length(viewPos.xz);
    float ao = color.a * color.a;
    vec3 worldNormal = normalize(ToWorld(normal * 1000000.0));

    //Vanilla Directional Lighting
    float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
          vanillaDiffuse *= vanillaDiffuse;
    #ifdef OVERWORLD
          vanillaDiffuse = mix(1.0, vanillaDiffuse, lightmap.y);
    #endif

    //Vanilla Block Lighting
    float blockLightMap = pow6(lightmap.x * lightmap.x) * 3.0 + max(lightmap.x - 0.05, 0.0);
          blockLightMap *= blockLightMap * 0.5;

    vec3 blockLighting = blockLightCol * blockLightMap * (1.0 - min(emission, 1.0));

    //Floodfill Lighting. Works only on Iris
    #if !defined GBUFFERS_BASIC && !defined GBUFFERS_WATER && !defined GBUFFERS_TEXTURED && defined IS_IRIS && !defined DH_TERRAIN && !defined DH_WATER
    vec3 voxelPos = worldToVoxel(worldPos);

    float floodfillFade = maxOf(abs(worldPos) / (voxelVolumeSize * 0.5));
          floodfillFade = clamp(floodfillFade, 0.0, 1.0);

    vec3 voxelLighting = vec3(0.0);

    if (isInsideVoxelVolume(voxelPos) && emission == 0.0) {
        vec3 voxelSamplePos = voxelPos + worldNormal;
             voxelSamplePos /= voxelVolumeSize;
             voxelSamplePos = clamp(voxelSamplePos, 0.0, 1.0);

        vec3 lightVolume = vec3(0.0);
        if ((frameCounter & 1) == 0) {
            lightVolume = texture3D(floodfillSamplerCopy, voxelSamplePos).rgb;
        } else {
            lightVolume = texture3D(floodfillSampler, voxelSamplePos).rgb;
        }
        voxelLighting = pow(lightVolume, vec3(1.0 / FLOODFILL_RADIUS));

        #ifdef GBUFFERS_ENTITIES
        voxelLighting += pow16(lightmap.x) * blockLightCol;
        #endif

        float mixFactor = 1.0 - floodfillFade * floodfillFade;

        blockLighting = mix(blockLighting, voxelLighting * FLOODFILL_BRIGHTNESS, mixFactor * 0.95);
    }
    #endif

    //Dynamic Hand Lighting
    #ifdef DYNAMIC_HANDLIGHT
    getHandLightColor(blockLighting, worldPos + relativeEyePosition);
    #endif

    //Shadow Calculation
    //Some code made by Emin and gri573
    #ifdef REALTIME_SHADOWS
    float shadowLightingFade = maxOf(abs(worldPos) / (vec3(shadowDistance, shadowDistance + 64.0, shadowDistance)));
          shadowLightingFade = clamp(shadowLightingFade, 0.0, 1.0);
          shadowLightingFade = 1.0 - pow3(shadowLightingFade);
    #else
    float shadowLightingFade = 0.0;
    #endif

    //Subsurface Scattering
    float sss = 0.0;

    if (0 < shadowLightingFade) {
        #ifdef REALTIME_SHADOWS
        #if defined OVERWORLD && defined GBUFFERS_TERRAIN
        if (0 < subsurface && 0 < lightmap.y) {
            float VoL = clamp(dot(normalize(viewPos), lightVec), 0.0, 1.0);
            sss = pow8(VoL) * shadowFade * (1.0 - wetness * 0.5);
            if (0.49 < subsurface && subsurface < 0.51) { //Leaves
                NoLm += 0.5 * shadowLightingFade * (0.75 + sss * 0.75);
            } else { //Foliage
                NoLm += 0.5 * shadowLightingFade * (0.25 + sss * 0.75) * (1.0 - float(subsurface > 0.29 && subsurface < 0.31) * 0.5);
            }
        }
        #endif

        float lightmapS = lightmap.y * lightmap.y * (3.0 - 2.0 * lightmap.y);

        vec3 worldPosM = worldPos;

        #ifdef GBUFFERS_TEXTURED
            vec3 centerWorldPos = floor(worldPos + cameraPosition) - cameraPosition + 0.5;
            worldPosM = mix(centerWorldPos, worldPosM + vec3(0.0, 0.02, 0.0), lightmapS);
        #else
            //Shadow bias without peter-panning
            float distanceBias = pow(dot(worldPos, worldPos), 0.75);
                  distanceBias = 0.12 + 0.0008 * distanceBias;
            vec3 bias = worldNormal * distanceBias * (2.0 - 0.95 * max(NoLm, 0.0));

            //Fix light leaking in caves
            if (lightmapS < 0.999) {
                #ifdef GBUFFERS_HAND
                    worldPosM = mix(vec3(0.0), worldPosM, 0.2 + 0.8 * lightmapS);
                #else
                    vec3 edgeFactor = 0.2 * (0.5 - fract(worldPosM + cameraPosition + worldNormal * 0.01));

                    #ifdef GBUFFERS_WATER
                        bias *= 0.7;
                        worldPosM += (1.0 - lightmapS) * edgeFactor;
                    #endif

                    worldPosM += (1.0 - pow2(pow2(max(color.a, lightmapS)))) * edgeFactor;
                #endif
            }

            worldPosM += bias;
        #endif
        
        vec3 shadowPos = ToShadow(worldPosM);

        float offset = 0.001 - shadowMapResolution * 0.0000001;
              offset *= 1.0 + subsurface * 3.0 * sqrt(1.0 - clamp(NoL, 0.0, 1.0));
        float viewDistance = 1.0 - clamp(lViewPos * 0.01, 0.0, 1.0);
        
        shadow = computeShadow(shadowPos, offset, lightmap.y, subsurface, viewDistance);
        #endif
    }

    vec3 realShadow = shadow;
    vec3 fakeShadow = getFakeShadow(lightmap.y);

    #if defined PBR && defined GBUFFERS_TERRAIN
    shadow *= parallaxShadow;
    #endif

    shadow *= clamp(NoLm * 1.01 - 0.01, 0.0, 1.0);
    #ifdef OVERWORLD
    fakeShadow *= clamp(NoL * 1.01 - 0.01, 0.0, 1.0);
    #else
    fakeShadow *= NoL;
    #endif

    shadow = mix(fakeShadow, shadow, vec3(shadowLightingFade));

    //Cloud Shadows
    float cloudShadow = 1.0;

    #ifdef VC_SHADOWS
    if (worldPos.y + cameraPosition.y < VC_HEIGHT - VC_THICKNESS + 45.0) {
        float speed = VC_SPEED;
        float amount = VC_AMOUNT;
        float frequency = VC_FREQUENCY;
        float density = VC_DENSITY;
        float height = VC_HEIGHT;

        getDynamicWeather(speed, amount, frequency, density, height);

        vec2 wind = vec2(frameTimeCounter * speed * 0.005, sin(frameTimeCounter * speed * 0.1) * 0.01) * speed * 0.1;
        vec3 worldSunVec = mat3(gbufferModelViewInverse) * lightVec;
        vec3 cloudShadowPos = worldPos + cameraPosition + (worldSunVec / max(abs(worldSunVec.y), 0.0)) * max((VC_HEIGHT + VC_THICKNESS + 45.0) - worldPos.y - cameraPosition.y, 0.0);

        float noise = 0.0;
        getCloudShadow(cloudShadowPos.xz, wind, amount, frequency, density, noise);

        cloudShadow = noise * VC_OPACITY;
    }
    shadow *= cloudShadow;
    #endif

    //Main Lighting
    #ifdef OVERWORLD
    #ifdef DISTANT_HORIZONS
    shadow *= lightmap.y;
    #endif

    float rainFactor = 1.0 - wetness * 0.75;
    vec3 sceneLighting = mix(ambientCol * pow4(lightmap.y), lightCol, shadow * rainFactor * shadowFade);
         sceneLighting *= 1.0 + sss * realShadow * shadowLightingFade;
    #elif defined END
    vec3 sceneLighting = mix(endAmbientCol, endLightCol, shadow) * 0.25;
    #elif defined NETHER
    vec3 sceneLighting = pow(netherColSqrt, vec3(0.75)) * 0.05;
    #endif

    //Specular Highlight
    vec3 specularHighlight = vec3(0.0);

    #if (defined GBUFFERS_TERRAIN || defined GBUFFERS_ENTITIES || defined GBUFFERS_BLOCK) && !defined NETHER
    if (emission < 0.01) {
        vec3 baseReflectance = vec3(0.1);

        float smoothnessF = 0.15 + length(albedo.rgb) * 0.2 + NoL * 0.2;
        #if defined DH_TERRAIN && defined END
              smoothnessF += 0.15;
        #endif
              smoothnessF = mix(smoothnessF, 0.95, smoothness);
        #ifndef GBUFFERS_TERRAIN
              smoothnessF *= float(subsurface < 0.001);
        #else
              smoothnessF *= float(subsurface < 0.001 && mat != 10314);
        #endif

        #ifdef OVERWORLD
        specularHighlight = getSpecularHighlight(normal, viewPos, smoothnessF, baseReflectance, lightCol, shadow * cloudShadow * vanillaDiffuse, color.a);
        #else
        specularHighlight = getSpecularHighlight(normal, viewPos, smoothnessF, baseReflectance, endLightCol * 0.25, shadow * vanillaDiffuse, color.a);
        #endif

        specularHighlight = clamp(specularHighlight * 4.0, vec3(0.0), vec3(8.0));
    }
    #endif

    //Minimal Lighting
    #if defined OVERWORLD || defined END
    sceneLighting += minLightCol * (1.0 - lightmap.y);
    #endif

    //Night vision
    sceneLighting += nightVision * vec3(0.1, 0.15, 0.1);

    //Lightning
    float lightning = min(lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 256.0) * lightningBoltPosition.w * 4.0, 1.0);
    sceneLighting += vec3(lightning) * (clamp(dot(lightningBoltPosition.xyz, worldNormal), 0.0, 1.0) * 0.9 + 0.1) * lightmap.y;

    //Aurora Lighting
    #if defined AURORA && defined AURORA_LIGHTING_INFLUENCE && !defined GBUFFERS_TEXTURED && !defined GBUFFERS_WATER && !defined GBUFFERS_BASIC
	float visibilityMultiplier = pow8(1.0 - sunVisibility) * (1.0 - wetness) * pow4(lightmap.y) * AURORA_BRIGHTNESS;
	float auroraVisibility = 0.0;

	#ifdef AURORA_FULL_MOON_VISIBILITY
	auroraVisibility = mix(auroraVisibility, 1.0, float(moonPhase == 0));
	#endif

	#ifdef AURORA_COLD_BIOME_VISIBILITY
	auroraVisibility = mix(auroraVisibility, 1.0, isSnowy);
	#endif

    #ifdef AURORA_ALWAYS_VISIBLE
    auroraVisibility = 1.0;
    #endif

	auroraVisibility *= visibilityMultiplier;
    sceneLighting += vec3(0.4, 2.5, 0.9) * 0.005 * auroraVisibility * (0.5 + NoU * 0.5);
    #endif

    //Vanilla AO
    #if defined VANILLA_AO && !defined GBUFFERS_HAND
    float aoMixer = (1.0 - ao) * (1.0 - pow6(lightmap.x)) * 1.5;
    #if !defined GBUFFERS_BASIC && !defined GBUFFERS_WATER && !defined GBUFFERS_TEXTURED && defined IS_IRIS && !defined DH_TERRAIN && !defined DH_WATER
          aoMixer *= 1.0 - min(length(voxelLighting), 1.0);
          aoMixer *= 1.0 - clamp(NoL, 0.0, 1.0) * 0.75;
    #endif
    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao, min(aoMixer, 1.0) * AO_STRENGTH);
    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao * ao, min(aoMixer, 1.0) * AO_STRENGTH * 0.5);
    #endif

    //RSM GI//
    vec3 gi = vec3(0.0);

    #if defined GI && (defined GBUFFERS_TERRAIN || defined GBUFFERS_ENTITIES)
    vec2 prevScreenPos = Reprojection(screenPos);
    gi = texture2D(gaux1, prevScreenPos).rgb;
    gi = pow4(gi) * 32.0 * lightmap.y * sunVisibility * shadowFade;

    #if defined OVERWORLD
    gi *= lightCol;
    #elif defined END
    gi *= endLightCol;
    #endif
    #endif

    albedo.rgb = pow(albedo.rgb, vec3(2.2));
    albedo.rgb *= sceneLighting * vanillaDiffuse + blockLighting + emission + specularHighlight + gi;
    albedo.rgb = pow(albedo.rgb, vec3(1.0 / 2.2));
}