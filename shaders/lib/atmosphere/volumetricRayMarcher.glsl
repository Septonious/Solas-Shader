#ifdef VL
float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}
#endif

#ifdef OVERWORLD_CLOUDY_FOG
#endif

void computeVolumetrics(inout vec4 result, in vec3 translucent, in float dither) {
    //Stuff which we're doing
    vec3 volumetricLighting = vec3(0.0);
    vec3 lpvFog = vec3(0.0);
    vec3 cloudyFog = vec3(0.0);
    float fireflies = 0.0;

	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;
    float linearDepth0 = getLinearDepth2(z0);
    float linearDepth1 = getLinearDepth2(z1);

    //Ray Marcher Parameters
    int sampleCount = 12 + int((1.0 - mefade) * 4);
    float maxDist = 96.0 + shadowDistance;
    #if defined VC_SHADOWS && defined VL
          maxDist += 128.0;
    #endif

    float minDist = (maxDist / sampleCount) * 0.75;
    float maxCurrentDist = min(linearDepth1, maxDist);

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
	float vlVisibility = float(0.56 < z0) * mix(visibilityDragon, visibilityNormal, clamp(dragonBattle, 0.0, 1.0));
	#endif

    #ifdef OVERWORLD
    vec3 newSkyColor = pow(normalize(skyColor + 0.0001), vec3(0.75));
    vec3 vlCol = mix(pow(lightCol, vec3(0.85)), lightCol * newSkyColor, timeBrightness);
    #else
    vec3 vlCol = endLightColSqrt;
    #endif

    #ifdef VC_SHADOWS
    float speed = VC_SPEED;
    float amount = VC_AMOUNT;
    float frequency = VC_FREQUENCY;
    float density = VC_DENSITY;
    float height = VC_HEIGHT;
    float cloudTop = VC_HEIGHT + VC_THICKNESS + 75.0 - timeBrightness * 30.0;

    getDynamicWeather(speed, amount, frequency, density, height);

    vec2 wind = vec2(frameTimeCounter * speed * 0.005, sin(frameTimeCounter * speed * 0.1) * 0.01) * speed * 0.1;
    #endif
    #endif

    //LPV Fog Variables
    float lpvIntensity = 50.0;
    #ifdef OVERWORLD
        lpvIntensity *= 1.0 - sunVisibility * eBS * 0.5;
        lpvIntensity += wetness * eBS * 50.0;
        lpvIntensity = mix(150.0, lpvIntensity, caveFactor);
    #endif
    #ifdef NETHER
        lpvIntensity = 120.0;
    #endif

    lpvIntensity *= LPV_FOG_STRENGTH;

    for (int i = 0; i < sampleCount; i++) {
        float currentDist = pow(i + dither, 1.0 + i / sampleCount) * minDist - 0.95;
              currentDist = mix(exp2(i + dither), currentDist, clamp(lViewPos * 0.01, 0.0, 1.0));

        if (currentDist > maxCurrentDist || linearDepth1 < currentDist || (linearDepth0 < currentDist && translucent.rgb == vec3(0.0))) {
            break;
        }
        
        vec3 worldPos = ToWorld(ToView(vec3(texCoord, getLogarithmicDepth(currentDist))));

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

        //Overworld ground cloudy fog
        #ifdef OVERWORLD_CLOUDY_FOG
        #endif

        //Translucency Blending
        if (linearDepth0 < currentDist) {
            volumetricLighting *= translucent;
            lpvFog *= translucent;
            cloudyFog *= translucent;
        }

        //Accumulate samples
        result.rgb += volumetricLighting;
        result.rgb += lpvFog;
        result.rgb += cloudyFog;
        result.a += fireflies;
    }
    result *= totalVisibility;
}