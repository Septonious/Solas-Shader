#if defined END_FLASHES && (!defined VOXY_OPAQUE && !defined VOXY_TRANSLUCENT)
uniform vec3 endFlashPosition;
uniform float endFlashIntensity;
#endif

void gbuffersLighting(in vec4 color, inout vec4 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 newNormal, inout vec3 shadow, in vec2 lightmap, 
                      in float NoU, in float NoL, in float NoE,
                      in float subsurface, in float emission, in float smoothness, in float parallaxShadow) {
    //Variables
    float originalNoL = NoL;
    float lViewPos = length(viewPos.xz);
    float lAlbedo = length(albedo.rgb);
    float vanillaAo = color.a * color.a;
    vec3 worldNormal = normalize(ToWorld(newNormal * 100000000.0));

    //Vanilla Directional Lighting
    float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
          vanillaDiffuse *= vanillaDiffuse;
          vanillaDiffuse = fmix(1.0, vanillaDiffuse, lightmap.y);

    //Block Lighting
    float blockLightMap = pow6(lightmap.x * lightmap.x) * 2.0 + max(lightmap.x - 0.05, 0.0);
          blockLightMap *= blockLightMap * 0.5;

    vec3 blockLighting = blockLightCol * blockLightMap * (1.0 - emission);

    //Floodfill Lighting. Works only on Iris
    #if !defined GBUFFERS_BASIC && !defined GBUFFERS_WATER && !defined GBUFFERS_TEXTURED && !defined DH_TERRAIN && !defined DH_WATER && defined VX_SUPPORT
    vec3 voxelPos = worldToVoxel(worldPos);

    float floodfillFade = maxOf(abs(worldPos) / (voxelVolumeSize * 0.5));
          floodfillFade = clamp(floodfillFade, 0.0, 1.0);

    vec3 voxelLighting = vec3(0.0);

    if (floodfillFade > 0 && emission == 0.0) {
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
        //voxelLighting *= sqrt(length(max(vec3(0.0), voxelLighting - vec3(0.02)))) * 2.0;

        #ifdef GBUFFERS_ENTITIES
        voxelLighting += pow16(lightmap.x) * blockLightCol;
        #endif

        float mixFactor = 1.0 - floodfillFade * floodfillFade;

        blockLighting = fmix(blockLighting, voxelLighting * FLOODFILL_BRIGHTNESS, mixFactor * 0.95);
    }
    #endif

    //Dynamic Hand Lighting
    #ifdef DYNAMIC_HANDLIGHT
    blockLighting += getHandLightColor(blockLighting, worldPos + relativeEyePosition);
    #endif

    //Dim blocklight in sunlight
    #ifdef OVERWORLD
    blockLighting *= 1.0 - lightmap.y * lightmap.y * 0.5 * sunVisibility;
    #endif

    //Shadow Calculations
    //Some code made by Emin and gri573
    float shadowVisibility = maxOf(abs(worldPos) / (vec3(min(shadowDistance, far))));
          shadowVisibility = clamp(shadowVisibility, 0.0, 1.0);
          shadowVisibility = 1.0 - pow3(shadowVisibility);

          #ifdef OVERWORLD
          shadowVisibility *= caveFactor;
          #endif

    //Subsurface scattering
    #if defined OVERWORLD
    float VoL = clamp(dot(normalize(viewPos), lightVec), 0.0, 1.0);
    #elif defined END
    float VoL = clamp(dot(normalize(viewPos), sunVec), 0.0, 1.0);
    #endif

    float sss = 0.0;

    #if defined OVERWORLD || defined END
    if (subsurface > 0.0) {
        sss = pow6(VoL);

        #ifdef OVERWORLD
        sss *= shadowFade;
        sss *= 1.0 - wetness * 0.5;
        #endif

        NoL = fmix(NoL, 1.0, subsurface * shadowVisibility * (0.5 + sss * 0.75) * 0.75);
    }
    #endif

    //Scene Lighting
    float fade = clamp(length(worldPos) * 0.01, 0.0, 1.0);
    vec3 worldPosM = worldPos;

    #ifndef NETHER
    #ifdef REALTIME_SHADOWS
    if (NoL > 0.0001 && shadowVisibility > 0.0) {
        float lightmapS = lightmap.y * lightmap.y * (3.0 - 2.0 * lightmap.y);

        #ifdef GBUFFERS_TEXTURED
            vec3 centerWorldPos = floor(worldPos + cameraPosition) - cameraPosition + 0.5;
            worldPosM = fmix(centerWorldPos, worldPosM + vec3(0.0, 0.02, 0.0), lightmapS);
        #else
            //Shadow bias without peter-panning
            float distanceBias = pow(dot(worldPos, worldPos), 0.75);
                    distanceBias = 0.1 + 0.0004 * distanceBias * (1.0 - float(subsurface > 0.01));
            vec3 bias = worldNormal * distanceBias;

            //Fix light leaking in caves
            if (lightmapS < 0.999) {
                #ifdef GBUFFERS_HAND
                    worldPosM = fmix(vec3(0.0), worldPosM, 0.2 + 0.8 * lightmapS);
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

        #if SHADOW_PIXEL > 0
        worldPosM = (floor((worldPosM + cameraPosition) * SHADOW_PIXEL + 0.01) + 0.5) / SHADOW_PIXEL - cameraPosition;
        #endif

        vec3 shadowPos = ToShadow(worldPosM);
        float offset = 0.001;

        computeShadow(shadow, shadowPos, offset, subsurface, lightmap.y);
    }
    #else
    shadowVisibility = 0.0;
    #endif

    NoL = clamp(NoL * 1.01 - 0.01, 0.0, 1.0);

    #if defined PBR && defined PARALLAX
    shadow *= parallaxShadow;
    #endif

    vec3 realShadow = shadow * NoL;
    vec3 fakeShadow = getFakeShadow(lightmap.y) * NoL;

    shadow = fmix(fakeShadow, realShadow, vec3(shadowVisibility));
    #endif

    float time = (worldTime + int(5 + mod(worldDay, 100)) * 24000) * 0.05;

    //Cloud Shadows
    float cloudShadow = 1.0;

    #ifdef VC_SHADOWS
    float speed = VC_SPEED;
    float amount = VC_AMOUNT;
    float frequency = VC_FREQUENCY;
    float thickness = VC_THICKNESS;
    float density = VC_DENSITY;
    float height = VC_HEIGHT;
    float scale = VC_SCALE;

    getDynamicWeather(speed, amount, frequency, thickness, density, height, scale);

    float cloudTop = height + thickness * scale;

    if (worldPos.y + cameraPosition.y < cloudTop) {
        vec2 wind = vec2(time * speed * 0.005, sin(time * speed * 0.1) * 0.01) * speed * 0.05;

        vec3 worldLightVec = mat3(gbufferModelViewInverse) * lightVec;
        vec3 cloudShadowPos = worldPos + cameraPosition + (worldLightVec / max(abs(worldLightVec.y), 0.0)) * max(cloudTop - worldPos.y - cameraPosition.y, 0.0);

        float noise = 0.0;
        getCloudShadow(cloudShadowPos.xz / scale, wind, amount, frequency, density, noise);

        cloudShadow = noise;
    }
    shadow *= cloudShadow;
    #endif

    //Specular Highlight
    vec3 specularHighlight = vec3(0.0);

    #if (defined GBUFFERS_TERRAIN || defined GBUFFERS_ENTITIES || defined GBUFFERS_BLOCK || defined VOXY_OPAQUE) && !defined NETHER && defined SPECULAR_HIGHLIGHTS
    if (emission < 0.01) {
        #if defined GBUFFERS_TERRAIN && defined OVERWORLD
        float isMaterialSmooth = float(mat >= 20298 && mat <= 20322);
        vec3 baseReflectance = vec3(max(5.0 - isMaterialSmooth * 4.0 - timeBrightness * 3.0, 1.0));
        #else
        vec3 baseReflectance = vec3(2.0);
        #endif

        float smoothnessF = 0.1 + lAlbedo * 0.25;
              smoothnessF = fmix(smoothnessF, 1.0, smoothness);

        specularHighlight = GGX(newNormal, normalize(viewPos), smoothnessF, baseReflectance, 0.04);
        specularHighlight = max(specularHighlight, 0.0);

        #if defined DH_TERRAIN
        specularHighlight *= 1.5;
        #endif
    }
    #endif

    //Main color mixing
    #ifdef OVERWORLD
    ambientCol *= 0.05 + lightmap.y * lightmap.y * 0.95;
    ambientCol *= 1.0 - pow(VoL, 1.5) * (0.5 - wetness * 0.5) * sunVisibility;
    lightCol *= 1.0 + specularHighlight * shadowFade * (0.5 + sunVisibility * 0.5);

    float rainFactor = 1.0 - wetness * 0.5;

    vec3 sceneLighting = fmix(ambientCol, lightCol, shadow * rainFactor * shadowFade) * (0.25 + lightmap.y * 0.75);
         sceneLighting *= 1.0 + sss * shadow * 2.0;

    #ifdef AURORA_LIGHTING_INFLUENCE
    //Total visibility of aurora based on multiple factors
    float auroraVisibility = pow6(moonVisibility) * (1.0 - wetness) * caveFactor;

    if (auroraVisibility > 0.0) {
        //The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
        float kpIndex = abs(worldDay % 9 - worldDay % 4);
              kpIndex = kpIndex - int(kpIndex == 1) + int(kpIndex > 7 && worldDay % 10 == 0);
              kpIndex = min(max(kpIndex, 0) + isSnowy * 4, 9);

        //Aurora tends to get brighter and dimmer when plasma arrives or fades away
        float pulse = 0.5 + 0.5 * sin(frameTimeCounter * 0.08 + sin(frameTimeCounter * 0.013) * 0.6);
              pulse = smoothstep(0.15, 0.85, pulse);

        float longPulse = sin(frameTimeCounter * 0.025 + sin(frameTimeCounter * 0.004) * 0.8);
              longPulse = longPulse * (1.0 - 0.15 * abs(longPulse));

        kpIndex *= 1.0 + longPulse * 0.25;
        kpIndex /= 9.0;
        auroraVisibility *= kpIndex * 0.5;
        sceneLighting *= (1.0 - auroraVisibility) + auroraVisibility * vec3(0.05 + (1.0 + pulse) * pow3(kpIndex), 1.55, 0.40);
    }
    #endif
    #elif defined END
    vec3 sceneLighting = fmix(endAmbientCol, endLightCol * (1.0 + specularHighlight), shadow) * 0.25;
    #ifdef END_FLASHES
    vec3 worldEndFlashPosition = mat3(gbufferModelViewInverse) * endFlashPosition;
    float endFlashDirection = clamp(dot(normalize(ToWorld(endFlashPosition * 100000000.0)), worldNormal), 0.0, 1.0);
    sceneLighting = fmix(sceneLighting, endFlashCol, 0.125 * endFlashDirection * endFlashDirection * endFlashIntensity);
    #endif
    #elif defined NETHER
    vec3 sceneLighting = pow(netherColSqrt, vec3(0.75)) * 0.025;
    #endif

    //Lightning Flash
    float lightningFlash = 0.0;

    #ifdef IS_IRIS
    if (lightningBoltPosition.w > 0) {
        lightningFlash = lightningFlashEffect(lightningBoltPosition, worldPos, lightmap.y, 256.0);
    }
    #endif

    //Minimal Lighting
    #ifdef OVERWORLD
    sceneLighting += minLightCol * (1.0 - lightmap.y) * (1.0 - eBS);
    #endif

    //Night vision
    sceneLighting += nightVision * vec3(0.2, 0.3, 0.2);

    //Vanilla vanillaAo
    float aoMixer = (1.0 - vanillaAo) * (1.0 - blockLightMap) * (1.0 - emission);
    #if defined OVERWORLD || defined END
            aoMixer *= 1.0 - float(length(shadow) > 0.0) * 0.5;
    #endif

    albedo.rgb = fmix(albedo.rgb, albedo.rgb * pow(vanillaAo, 1.0 + lightmap.y), aoMixer);

    albedo.rgb = pow(albedo.rgb, vec3(2.2));
    albedo.rgb *= sceneLighting + blockLighting + emission * EMISSION_STRENGTH + lightningFlash;
    albedo.rgb *= vanillaDiffuse;
    albedo.rgb = pow(albedo.rgb, vec3(1.0 / 2.2));
}