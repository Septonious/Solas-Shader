#ifdef VL
float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}
#endif

#ifdef OVERWORLD_CLOUDY_FOG
#include "/lib/atmosphere/overworldCloudyFog.glsl"
#endif

#ifdef NETHER_SMOKE
#include "/lib/atmosphere/netherSmoke.glsl"
#endif

#ifdef FIREFLIES
#include "/lib/atmosphere/fireflies.glsl"
#endif

void computeVolumetrics(inout vec4 result, in vec3 translucent, in float dither) {
    //Stuff which we're doing
    vec3 volumetricLighting = vec3(0.0);
    vec3 cloudyFog = vec3(0.0);
    vec3 lpvFog = vec3(0.0);
    float fireflies = 0.0;

	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;
    float linearDepth0 = getLinearDepth2(z0);
    float linearDepth1 = getLinearDepth2(z1);

	//Positions & Common variables
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
	vec3 worldSunVec = mat3(gbufferModelViewInverse) * lightVec;
	vec3 viewPos = ToView(vec3(texCoord.xy, z0));
	vec3 nViewPos = normalize(viewPos);
    float lViewPos = length(viewPos);

	float VoL = dot(nViewPos, lightVec);
	float VoU = dot(nViewPos, upVec);
	float VoLC = clamp(VoL, 0.0, 1.0);
	float VoUC = clamp(VoU, 0.0, 1.0);
          VoLC *= min(1.0 + VoU, 1.0);
          VoLC = pow(VoLC, 1.25);

    float totalVisibility = float(z0 > 0.56);

	#if MC_VERSION >= 11900
	totalVisibility *= 1.0 - darknessFactor;
	#endif

	totalVisibility *= 1.0 - blindFactor;

    float speed = VC_SPEED;
    #ifdef VC_SHADOWS
    float amount = VC_AMOUNT;
    float frequency = VC_FREQUENCY;
    float density = VC_DENSITY;
    float height = VC_HEIGHT;
    float cloudTop = VC_HEIGHT + VC_THICKNESS + 75.0 - timeBrightness * 30.0;

    getDynamicWeather(speed, amount, frequency, density, height);
    #endif

    vec2 wind = vec2(frameTimeCounter * speed * 0.005, sin(frameTimeCounter * speed * 0.1) * 0.01) * speed * 0.1;

    //Ray Marcher Parameters
    int sampleCount = VL_SAMPLES;
    #ifdef OVERWORLD
        sampleCount += int((1.0 - mefade) * 4);
    #endif
    float maxDist = 96.0 + shadowDistance;
    #if defined VC_SHADOWS && defined VL
          maxDist += 128.0;
    #endif

    float minDist = (maxDist / sampleCount) * 0.75;
    float maxCurrentDist = min(linearDepth1, maxDist);
    float distanceMixer = 1.0 - clamp(lViewPos * 0.005, 0.0, 1.0);

    //Volumetric Lighting Variables
    #ifdef VL
	#ifdef OVERWORLD
        float VoLExt = pow(VoL * 0.5 + 0.5, 1.5);
        float sunVisibilityM = pow(sunVisibility, 0.33);
        float meVisRatio = (1.0 - VL_STRENGTH_RATIO) + clamp(VoLC * VL_STRENGTH_RATIO, 0.0, VL_STRENGTH_RATIO);
        float vlVisibility = mix(VL_NIGHT, mix(VL_MORNING_EVENING, VL_DAY, timeBrightness), sunVisibilityM);
              vlVisibility *= mix(meVisRatio, VoLExt, min(timeBrightness + (1.0 - sunVisibilityM), 1.0));
            #if !defined VC_SHADOWS || !defined VC
              vlVisibility *= 1.0 - VoU;
            #endif
              vlVisibility = mix(vlVisibility, VoLExt * 0.5, float(isEyeInWater == 1));
              vlVisibility *= caveFactor * shadowFade;
              vlVisibility /= sampleCount;
	#else
        float dragonBattle = 1.0;
        #if MC_VERSION <= 12104
              dragonBattle = gl_Fog.start / far;
        #endif
        float endBlackHolePos = pow2(clamp(dot(nViewPos, sunVec), 0.0, 1.0));
        float visibilityNormal = endBlackHolePos * 0.25;
        float visibilityDragon = 0.25 + endBlackHolePos * 0.5;
        float vlVisibility = float(0.56 < z0) * mix(visibilityDragon, visibilityNormal, clamp(dragonBattle, 0.0, 1.0)) * 0.25;
	#endif

    #ifdef OVERWORLD
        vec3 newSkyColor = pow(normalize(skyColor + 0.0001), vec3(0.75));
        vec3 vlCol = mix(pow(lightCol, vec3(0.85)), lightCol * newSkyColor, timeBrightness);
    #else
        vec3 vlCol = endLightColSqrt;
    #endif

    vlVisibility *= VL_STRENGTH;
    vlVisibility *= min(1.0, length(viewPos) * 0.01);
    #endif

    //LPV Fog Variables
    float lpvIntensity = 40.0;
    #ifdef OVERWORLD
        lpvIntensity *= 1.0 - sunVisibility * eBS * 0.5;
        lpvIntensity += wetness * eBS * 50.0;
        lpvIntensity = mix(60.0, lpvIntensity, caveFactor);
    #endif
    #ifdef NETHER
        lpvIntensity = 25.0;
    #endif

    lpvIntensity *= LPV_FOG_STRENGTH;

    //Cloudy Fog Variables
    #ifdef OVERWORLD_CLOUDY_FOG
    float cloudyFogVisibility = isJungle + isSwamp + isDesert + isMesa + isSavanna;
          cloudyFogVisibility *= sunVisibility * (1.0 - timeBrightness);

    vec3 cloudyFogCol = skyColor * biomeColor;
         cloudyFogCol = normalize(cloudyFogCol) * 2.0;
    #endif

    #ifdef NETHER_SMOKE
    vec3 wind2 = vec3(-sin(frameTimeCounter * 0.3) * 0.2, -4.0 * frameTimeCounter, cos(frameTimeCounter * 0.5) * 0.4);
    #endif

    //Fireflies Variables
    #ifdef FIREFLIES
    float ffIntensity = pow(eBS, 0.25) * (1.0 - sunVisibility) * (1.0 - wetness) * float(isEyeInWater == 0);
    vec3 wind3 = vec3(sin(frameTimeCounter * 0.50), - sin(frameTimeCounter * 0.75), cos(frameTimeCounter * 1.25));
    #endif

    //Ray Marching
    for (int i = 0; i < sampleCount; i++) {
        #ifdef OVERWORLD
        float currentDist = pow(i + dither, 1.0 + i / sampleCount) * minDist;
              currentDist = mix(currentDist, exp2(i + dither), distanceMixer);
        #else
        float currentDist = exp2(i + dither) * 4.0;
        #endif

        if (currentDist > maxCurrentDist || linearDepth1 < currentDist || (linearDepth0 < currentDist && translucent.rgb == vec3(0.0))) {
            break;
        }
        
        vec3 worldPos = ToWorld(ToView(vec3(texCoord, getLogarithmicDepth(currentDist))));
        float lWorldPos = length(worldPos);
        float lWorldPosXZ = length(worldPos.xz);

        //VL calculations
        #ifdef VL
        if (vlVisibility > 0.0) {
            vec3 shadowCol = vec3(0.0);

            float shadow0 = 1.0;
            float shadow1 = 0.0;

            if (length(worldPos.xz) <= shadowDistance) {
                vec3 shadowPos = ToShadow(worldPos);
                shadow0 = texture2DShadow(shadowtex0, shadowPos);

                #ifdef SHADOW_COLOR
                if (shadow0 < 1.0) {
                    shadow1 = texture2DShadow(shadowtex1, shadowPos);
                    if (shadow1 > 0.0) {
                        shadowCol = texture2D(shadowcolor0, shadowPos.xy).rgb;
                    }
                }
                #endif
            }

            volumetricLighting = clamp(shadow1 * shadowCol + shadow0 * vlCol * float(isEyeInWater == 0), 0.0, 1.0);

            //Crepuscular rays
            #ifdef VC_SHADOWS
            if (worldPos.y + cameraPosition.y < cloudTop) {
                vec3 cloudShadowPos = worldPos + cameraPosition + (worldSunVec / max(abs(worldSunVec.y), 0.0)) * max(cloudTop - worldPos.y - cameraPosition.y, 0.0);

                float noise = 0.0;
                getCloudShadow(cloudShadowPos.xz, wind, amount, frequency, density, noise);
                volumetricLighting *= noise;
            }
            volumetricLighting *= 1.0 - min((worldPos.y + cameraPosition.y - VC_THICKNESS) * (1.0 / cloudTop), 1.0);
            #endif

            //Overworld ground cloudy fog
            #ifdef OVERWORLD_CLOUDY_FOG
            vec3 fogPos = worldPos + cameraPosition;
            float fogSample = 0.0;
            if (fogPos.y > 0.0 && fogPos.y < 100.0 && length(volumetricLighting) > 0.0 && cloudyFogVisibility > 0.0) {
                fogSample = getOverworldFogSample(fogPos, wind);
                fogSample *= max(0.0, 1.0 - lWorldPosXZ * 0.0025);
            }
            float altitudeFactor = clamp(fogPos.y * 0.01, 0.0, 1.0);
            volumetricLighting *= mix(1.0, fogSample * 8.0, altitudeFactor * (1.0 - altitudeFactor) * cloudyFogVisibility);
            #endif

            volumetricLighting *= vlVisibility;
        }
        #endif

        //LPV Fog calculations
        #ifdef LPV_FOG
        vec3 voxelPos = worldToVoxel(worldPos);
             voxelPos /= voxelVolumeSize;
             voxelPos = clamp(voxelPos, 0.0, 1.0);

        if (isInsideVoxelVolume(voxelPos)) {
            float currentSampleIntensity = (currentDist / maxDist) / sampleCount;
            float floodfillFade = maxOf(abs(worldPos) / (voxelVolumeSize * 0.5));
                  floodfillFade = clamp(floodfillFade, 0.0, 1.0);

            vec4 lightVolume = vec4(0.0);
            if ((frameCounter & 1) == 0) {
                lightVolume = texture(floodfillSamplerCopy, voxelPos);
            } else {
                lightVolume = texture(floodfillSampler, voxelPos);
            }

            lpvFog = pow(lightVolume.rgb, vec3(1.0 / FLOODFILL_RADIUS)) * (1.0 - floodfillFade * floodfillFade);
            lpvFog *= lpvIntensity * currentSampleIntensity;
        }
        #endif

        //Nether Cloudy Fog
        #ifdef NETHER_SMOKE
        if (lWorldPos < 128.0) {
            float currentSampleIntensity = (currentDist / maxDist) / sampleCount;
            float fogSample = getNetherFogSample(worldPos + cameraPosition + wind2);
            cloudyFog += netherCol * fogSample * currentSampleIntensity * 64.0;
        }
        #endif

        //Fireflies
        #ifdef FIREFLIES
        if (lWorldPosXZ < 64.0) {
            vec3 npos = worldPos + cameraPosition;
                 npos += calculateMovement(npos, 0.6, 3.0, vec2(2.6, 1.3));
                 npos += wind3;

            float fireflyNoise = getFireflyNoise(npos * 1.5);
                  fireflyNoise = clamp(fireflyNoise - 0.725, 0.0, 1.0);

            fireflies += fireflyNoise * (1.0 - clamp(npos.y * 0.01, 0.0, 1.0)) * ffIntensity * 256.0;
        }
        #endif

        //Translucency Blending
        if (linearDepth0 < currentDist) {
            volumetricLighting *= translucent;
            cloudyFog *= translucent;
            lpvFog *= translucent;
        }

        //Accumulate samples
        result.rgb += volumetricLighting;
        result.rgb += cloudyFog;
        result.rgb += lpvFog;
        result.a += fireflies;
    }
    result *= totalVisibility;
}