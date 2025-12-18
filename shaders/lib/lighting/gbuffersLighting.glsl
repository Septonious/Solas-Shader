#if MC_VERSION >= 12100
uniform vec3 endFlashPosition;
uniform float endFlashIntensity;

float endFlashPosToPoint(vec3 flashPosition, vec3 worldPos) {
    vec3 flashPos = mat3(gbufferModelViewInverse) * flashPosition;
    vec2 flashCoord = flashPos.xz / (flashPos.y + length(flashPos));
    vec2 planeCoord = worldPos.xz / (length(worldPos) + worldPos.y) - flashCoord;
    float flashPoint = 1.0 - clamp(length(planeCoord), 0.0, 1.0);

    return flashPoint;
}
#endif

void gbuffersLighting(inout vec4 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 newNormal, inout vec3 shadow, in vec2 lightmap, 
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
          vanillaDiffuse = mix(1.0, vanillaDiffuse, lightmap.y);

    //Block Lighting
    float blockLightMap = pow6(lightmap.x * lightmap.x) * 2.0 + max(lightmap.x - 0.05, 0.0);
          blockLightMap *= blockLightMap * 0.5;

    vec3 blockLighting = blockLightCol * blockLightMap * (1.0 - min(emission, 1.0));

    //Floodfill Lighting. Works only on Iris
    #if !defined GBUFFERS_BASIC && !defined GBUFFERS_WATER && !defined GBUFFERS_TEXTURED && !defined DH_TERRAIN && !defined DH_WATER && defined VX_SUPPORT
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
        //voxelLighting *= sqrt(length(max(vec3(0.0), voxelLighting - vec3(0.02)))) * 2.0;

        #ifdef GBUFFERS_ENTITIES
        voxelLighting += pow16(lightmap.x) * blockLightCol;
        #endif

        float mixFactor = 1.0 - floodfillFade * floodfillFade;

        blockLighting = mix(blockLighting, voxelLighting * FLOODFILL_BRIGHTNESS, mixFactor * 0.95);
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

        NoL += subsurface * shadowVisibility * (0.3 + sss * 0.7);
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
            worldPosM = mix(centerWorldPos, worldPosM + vec3(0.0, 0.02, 0.0), lightmapS);
        #else
            //Shadow bias without peter-panning
            float distanceBias = pow(dot(worldPos, worldPos), 0.75);
                  distanceBias = 0.1 + 0.0004 * distanceBias * (1.0 - float(subsurface > 0.0));
            vec3 bias = worldNormal * distanceBias;

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
        float offset = 0.00075 - shadowMapResolution * 0.0000001; 
              offset *= 1.0 + subsurface * (3.0 - 3.5 * fade);

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
    vec3 fakeShadow = getFakeShadow(lightmap.y) * originalNoL;

    shadow = mix(fakeShadow, realShadow, vec3(shadowVisibility));
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
        vec2 wind = vec2(time * speed * 0.005, sin(time * speed * 0.1) * 0.01) * speed * 0.1;
        vec3 worldSunVec = mat3(gbufferModelViewInverse) * lightVec;
        vec3 cloudShadowPos = worldPos + cameraPosition + (worldSunVec / max(abs(worldSunVec.y), 0.0)) * max(cloudTop - worldPos.y - cameraPosition.y, 0.0);

        float noise = 0.0;
        getCloudShadow(cloudShadowPos.xz / scale, wind, amount, frequency, density, noise);

        cloudShadow = noise * VC_OPACITY;
    }
    shadow *= cloudShadow;
    #endif

    //Specular Highlight
    vec3 specularHighlight = vec3(0.0);

    #if (defined GBUFFERS_TERRAIN || defined GBUFFERS_ENTITIES || defined GBUFFERS_BLOCK) && !defined NETHER && defined SPECULAR_HIGHLIGHTS
    if (emission < 0.01) {
        #if defined GBUFFERS_TERRAIN && defined OVERWORLD
        float isMaterialSmooth = float(mat >= 20298 && mat <= 20322);
        vec3 baseReflectance = vec3(max(6.0 - isMaterialSmooth * 5.0 - timeBrightness * 4.0, 1.0));
        #else
        vec3 baseReflectance = vec3(2.0);
        #endif

        float smoothnessF = 0.1 + lAlbedo * 0.25;
              smoothnessF = mix(smoothnessF, 1.0, smoothness);

        specularHighlight = clamp(GGX(newNormal, normalize(viewPos), smoothnessF, baseReflectance, 0.04), vec3(0.0), vec3(4.0));

        #ifdef DH_TERRAIN
        specularHighlight *= 4.0;
        #endif
    }
    #endif

    //Main color mixing
    #ifdef OVERWORLD
    ambientCol *= 0.05 + lightmap.y * lightmap.y * 0.95;
    ambientCol *= 1.0 - pow(VoL, 1.5) * (0.5 - wetness * 0.5) * sunVisibility;
    lightCol *= 1.0 + specularHighlight * shadowFade * (0.5 + sunVisibility * 0.5);

    float rainFactor = 1.0 - wetness * 0.5;

    vec3 sceneLighting = mix(ambientCol, lightCol, shadow * rainFactor * shadowFade) * (0.25 + lightmap.y * 0.75);
         sceneLighting *= 1.0 + sss * shadow * 2.0;

    #ifdef AURORA_LIGHTING_INFLUENCE
	//The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
    float kpIndex = abs(worldDay % 9 - worldDay % 4);
          kpIndex = kpIndex - int(kpIndex == 1) + int(kpIndex > 7 && worldDay % 10 == 0);
          kpIndex = min(max(kpIndex, 0), 9);

	#ifdef AURORA_FULL_MOON_VISIBILITY
	      kpIndex += float(moonPhase == 0) * 3;
	#endif

	#ifdef AURORA_COLD_BIOME_VISIBILITY
	      kpIndex += isSnowy * 4;
	#endif

    #ifdef AURORA_ALWAYS_VISIBLE
	      kpIndex = 9.0;
    #endif

	//Total visibility of aurora based on multiple factors
	float auroraVisibility = pow6(moonVisibility) * (1.0 - wetness) * caveFactor;

    //Aurora tends to get brighter and dimmer when plasma arrives or fades away
	float pulse = clamp(cos(sin(time * 0.1) * 0.3 + time * 0.07), 0.0, 1.0);
	float longPulse = clamp(sin(cos(time * 0.01) * 0.4 + time * 0.06), -1.0, 1.0);

    kpIndex *= 1.0 + longPulse * 0.25;
	kpIndex /= 9.0;
	auroraVisibility *= kpIndex;
    auroraVisibility = min(auroraVisibility, 1.0) * AURORA_BRIGHTNESS;
    sceneLighting *= (1.0 - auroraVisibility) + mix(vec3(0.4, 1.5, 0.6), vec3(3.4, 0.1, 1.5), clamp(kpIndex * kpIndex * (0.25 + pulse * 0.75), 0.0, 1.0)) * max(auroraVisibility, 0.0);
    #endif
    #elif defined END
    vec3 sceneLighting = mix(endAmbientCol, endLightCol * (1.0 + specularHighlight), shadow) * 0.25;
    #ifdef END_FLASHES
    vec3 worldEndFlashPosition = mat3(gbufferModelViewInverse) * endFlashPosition;
    float endFlashDirection = clamp(dot(normalize(ToWorld(endFlashPosition * 100000000.0)), worldNormal), 0.0, 1.0);
    sceneLighting = mix(sceneLighting, endFlashCol, 0.125 * endFlashDirection * endFlashDirection * endFlashIntensity);
    #endif
    #elif defined NETHER
    vec3 sceneLighting = pow(netherColSqrt, vec3(0.75)) * 0.025;
    #endif

    //Lightning Flash
    float lightning = min(lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 256.0) * lightningBoltPosition.w * 4.0, 1.0);
    vec3 lightningFlash = vec3(lightning) * (clamp(dot(lightningBoltPosition.xyz, worldNormal), 0.0, 1.0) * 0.9 + 0.1) * lightmap.y;

    //Minimal Lighting
    #ifdef OVERWORLD
    sceneLighting += minLightCol * (1.0 - lightmap.y) * (1.0 - eBS);
    #endif

    //Night vision
    sceneLighting += nightVision * vec3(0.2, 0.3, 0.2);

    //Vanilla vanillaAo
    float aoMixer = (1.0 - vanillaAo) * (1.0 - blockLightMap) * (1.0 - float(emission > 0.0)) * (1.0 - subsurface * 0.5);

    //#if defined OVERWORLD || defined END
    //aoMixer *= 1.0 - float(length(realShadow) > 0.0);
    //#endif

    albedo.rgb = mix(albedo.rgb, albedo.rgb * pow(vanillaAo, 1.0 + lightmap.y), aoMixer);

    albedo.rgb = pow(albedo.rgb, vec3(2.2));
    albedo.rgb *= sceneLighting + blockLighting + emission * EMISSION_STRENGTH + lightningFlash;
    albedo.rgb *= vanillaDiffuse;
    albedo.rgb = pow(albedo.rgb, vec3(1.0 / 2.2));
}