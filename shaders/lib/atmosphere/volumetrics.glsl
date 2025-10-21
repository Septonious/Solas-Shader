#ifdef VL
float texture2DShadow(sampler2D shadowtex, vec3 sampleShadowPos) {
    float shadow = texture2D(shadowtex, sampleShadowPos.xy).r;

    return clamp((shadow - sampleShadowPos.z) * 65536.0, 0.0, 1.0);
}
#endif

#ifdef NETHER_SMOKE
float getNetherFogSample(vec3 fogPos) {
    fogPos.x *= 0.5 + cos(fogPos.y * 0.5 + frameTimeCounter * 0.3 + fract(fogPos.z * 0.01) * 0.5) * 0.00004;
    fogPos.z *= 0.5 + sin(fogPos.y * 0.7 + frameTimeCounter * 0.15 + fract(fogPos.x * 0.01) * 0.3) * 0.00006;

    float n3da = texture2D(noisetex, fogPos.xz * 0.005 + floor(fogPos.y * 0.1) * 0.1).r;
    float n3db = texture2D(noisetex, fogPos.xz * 0.005 + floor(fogPos.y * 0.1 + 1.0) * 0.1).r;

    float cloudyNoise = mix(n3da, n3db, fract(fogPos.y * 0.1));
          cloudyNoise = max(cloudyNoise - 0.5, 0.0);
          cloudyNoise *= 1.0 + pow3(cloudyNoise) * 64.0;
    return cloudyNoise;
}
#endif

bool isRayMarcherHit(float currentDist, float maxDist, float linearZ0, float linearZ1, vec3 translucent) {
	bool isMaxReached = currentDist >= maxDist;
	bool opaqueReached = currentDist > linearZ1;
	bool solidTransparentReached = currentDist > linearZ0 && translucent == vec3(0.0);
	
	return isMaxReached || opaqueReached || solidTransparentReached;
}

#ifdef VL
void calculateVLParameters(inout float intensity, inout float distanceFactor, inout float samplePersistence, in float VoU, in float VoL) {
    float VoLPositive = VoL * 0.5 + 0.5;
    float VoUPositive = VoU * 0.5 + 0.5;
    float VoLClamped = clamp(VoL, 0.0, 1.0);
    float VoUClamped = clamp(VoU, 0.0, 1.0);

    float timeIntensityFactor = mix(VL_NIGHT * 2.0, mix(VL_MORNING_EVENING, VL_DAY, timeBrightness), sunVisibility);

    float averageDepth = 0.0;
	for (float i = 0.1; i < 1.0; i += 0.1) {
		float depthSample = texelFetch(depthtex0, ivec2(viewWidth * i * 0.55, viewHeight * 0.65), 0).r;
			  depthSample = pow4(depthSample);
		averageDepth += depthSample * 0.1;
	}
    float closedSpaceFactor = 1.0 - min(1.0, pow8(eBS) * 0.5 + averageDepth * (0.85 - eBS * eBS * 0.3));

    intensity = (sunVisibility * (1.0 - VL_STRENGTH_RATIO) + VoL * VL_STRENGTH_RATIO) * (1.0 - timeBrightness) + VoLPositive * VoLPositive * timeBrightness;
    intensity = mix(intensity * timeIntensityFactor, timeIntensityFactor * 2.0, closedSpaceFactor);

    #ifdef VC_SHADOWS
    intensity = mix(intensity, 1.0 + VoLPositive * VoLPositive * float(isEyeInWater == 1), clamp((cameraPosition.y - VC_HEIGHT) * 0.01 + float(isEyeInWater == 1), 0.0, 1.0));
    #else
    intensity *= max(pow4(1.0 - VoUClamped), float(isEyeInWater == 1));
    #endif

    intensity *= VL_STRENGTH * shadowFade * caveFactor;
    samplePersistence *= 1.0 - closedSpaceFactor * 0.25 - float(isEyeInWater == 1) * 0.25;
    distanceFactor = float(isEyeInWater) * 5.0;
}
#endif

void computeVolumetricLight(inout vec3 vl, in vec3 translucent, in float dither) {
	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;
	float linearZ0 = getLinearDepth(z0, gbufferProjectionInverse);
	float linearZ1 = getLinearDepth(z1, gbufferProjectionInverse);

    #ifdef DISTANT_HORIZONS
	float DHz0 = texture2D(dhDepthTex0, texCoord).r;
	float DHz1 = texture2D(dhDepthTex1, texCoord).r;
	float DHlinearZ0 = getLinearDepth(DHz0, dhProjectionInverse);
	float DHlinearZ1 = getLinearDepth(DHz1, dhProjectionInverse);

    linearZ0 = min(linearZ0, DHlinearZ0);
    linearZ1 = min(linearZ1, DHlinearZ1);
    #endif

	//Positions & Common variables
	vec3 viewPos = ToView(vec3(texCoord.xy, z1));
    vec3 worldPos = ToWorld(viewPos);
	vec3 nViewPos = normalize(viewPos);
	vec3 nWorldPos = normalize(worldPos);
	     nWorldPos /= -nViewPos.z;

    float lViewPos = length(viewPos);

    #ifndef NETHER_SMOKE
    #ifdef VC_SHADOWS
	vec3 wSunVec = mat3(gbufferModelViewInverse) * lightVec;
    #endif

    float VoL = dot(nViewPos, lightVec);
    float VoU = dot(nViewPos, upVec);
    #endif

    float totalVisibility = float(z0 > 0.56) * float(isEyeInWater != 2);

	#if MC_VERSION >= 11900
	totalVisibility *= 1.0 - darknessFactor;
	#endif

	totalVisibility *= 1.0 - blindFactor;

    //Volumetric Lighting Variables
    float vlIntensity = 0.0;

    #ifdef VL
    float vlSamplePersistence = 1.0; //Expected range: 0.1 - 1.0. Defines the VL's falloff. Lower values make VL stronger
    float vlDistanceFactor = 0.0; //Expected range: 0.0 - 10.0. Limits VL's maximum distance. Higher values decrease maxDist

    calculateVLParameters(vlIntensity, vlDistanceFactor, vlSamplePersistence, VoU, VoL);

    vec3 nSkyColor = normalize(skyColor + 0.000001) * mix(vec3(1.0), biomeColor, sunVisibility * isSpecificBiome);
    vec3 vlCol = mix(lightCol, nSkyColor, timeBrightness * 0.75);
    #endif

    #ifdef NETHER_SMOKE
    vlIntensity = NETHER_SMOKE_STRENGTH;
    #endif

    //LPV Fog Variables
    float lpvFogIntensity = LPV_FOG_STRENGTH * (5.0 - float(isEyeInWater == 1) * 4.0);
    #ifdef OVERWORLD
          lpvFogIntensity *= (2.0 - eBS * timeBrightnessSqrt - caveFactor);
    #elif defined END
          lpvFogIntensity *= 2.0;
    #endif

    if (totalVisibility > 0.0) {
        //Crepuscular rays parameters
        #if defined VC_SHADOWS && defined VL
		float speed = VC_SPEED;
		float amount = VC_AMOUNT;
		float frequency = VC_FREQUENCY;
		float thickness = VC_THICKNESS;
		float density = VC_DENSITY;
		float height = VC_HEIGHT;
        float scale = VC_SCALE;

        getDynamicWeather(speed, amount, frequency, thickness, density, height, scale);

        float cloudTop = height + thickness * scale - 50.0;
        float time = (worldTime + int(5 + mod(worldDay, 100)) * 24000) * 0.05;
        vec2 wind = vec2(time * speed * 0.005, sin(time * speed * 0.1) * 0.01) * 0.1;
        #endif

        //Nether Smoke Animation
        #ifdef NETHER_SMOKE
        vec3 wind2 = vec3(-sin(frameTimeCounter * 0.3) * 0.2, -4.0 * frameTimeCounter, cos(frameTimeCounter * 0.5) * 0.4);
        #endif

        //Ray marcher parameters
        int sampleCount = VL_SAMPLES;

        float maxDist = shadowDistance;
        #ifdef VC_SHADOWS
            maxDist += 128.0;
        #endif

        #ifdef VL
            maxDist /= 1.0 + vlDistanceFactor;
        #endif

        //Ray marching
        for (int i = 0; i < sampleCount; i++) {
            float currentDist = exp2(i + dither);

            if (isRayMarcherHit(currentDist, maxDist, linearZ0, linearZ1, translucent)) break;

            vec3 sampleWorldPos = nWorldPos * currentDist;
            float lWorldPos = length(sampleWorldPos);

            if (lWorldPos > maxDist) break;

            float currentSampleIntensityLPV = currentDist / maxDist / sampleCount;
            float currentSampleIntensityVL = currentDist / maxDist / sampleCount;
            #ifdef VL
                  currentSampleIntensityVL = pow(currentSampleIntensityVL, vlSamplePersistence);
            #endif

            vec3 rayPos = sampleWorldPos + cameraPosition;

            //Volumetric lighting
            vec3 vlSample = vec3(0.0);

            #ifdef VL
            if (vlIntensity > 0.0) {
                vec3 shadowCol = vec3(0.0);
                float shadow0 = 1.0;
                float shadow1 = 0.0;

                vec3 sampleShadowPos = ToShadow(sampleWorldPos);
                if (length(sampleShadowPos.xy * 2.0 - 1.0) < 1.0) {
                    shadow0 = texture2DShadow(shadowtex0, sampleShadowPos);

                    #ifdef SHADOW_COLOR
                    if (shadow0 < 1.0) {
                        shadow1 = texture2DShadow(shadowtex1, sampleShadowPos);
                        if (shadow1 > 0.0) {
                            shadowCol = texture2D(shadowcolor0, sampleShadowPos.xy).rgb;
                        }
                    }
                    #endif
                    float lShadowCol = min(1.0, length(shadowCol * shadowCol * shadowCol * shadowCol * shadowCol * shadowCol));
                    vlSample = clamp(shadow1 * shadowCol * shadowCol * mix(vec3(1.0), 32.0 * pow(waterColor, vec3(1.0 - lShadowCol * 0.5)) * lShadowCol, vec3(float(isEyeInWater == 1))) + shadow0 * vlCol * float(isEyeInWater == 0), 0.0, 1.0);
                }

                //Crepuscular rays
                #ifdef VC_SHADOWS
                if (rayPos.y < cloudTop) {
                    vec3 cloudShadowPos = rayPos + (wSunVec / max(abs(wSunVec.y), 0.0)) * max(cloudTop - rayPos.y, 0.0);

                    float noise = 0.0;
                    getCloudShadow(cloudShadowPos.xz / scale, wind, amount, frequency, density, noise);
                    vlSample *= noise;
                }
                vlSample *= 1.0 - min((rayPos.y - thickness) * (1.0 / cloudTop), 1.0);
                #endif
            }
            #endif

            //LPV Fog
            vec3 lpvFogSample = vec3(0.0);

            #ifdef LPV_FOG
            if (lpvFogIntensity > 0.0) {
                vec3 voxelPos = worldToVoxel(sampleWorldPos);
                     voxelPos /= voxelVolumeSize;
                     voxelPos = clamp(voxelPos, 0.0, 1.0);

                if (isInsideVoxelVolume(voxelPos)) {
                    float floodfillFade = maxOf(abs(sampleWorldPos) / (voxelVolumeSize * 0.5));
                          floodfillFade = clamp(floodfillFade, 0.0, 1.0);

                    vec4 lightVolume = vec4(0.0);
                    if ((frameCounter & 1) == 0) {
                        lightVolume = texture(floodfillSamplerCopy, voxelPos);
                    } else {
                        lightVolume = texture(floodfillSampler, voxelPos);
                    }

                    lpvFogSample = pow(lightVolume.rgb, vec3(1.0 / FLOODFILL_RADIUS)) * (1.0 - floodfillFade * floodfillFade);

                    #ifdef LPV_CLOUDY_FOG
                    vec3 noisePos = rayPos * 3.0;
                    float n3da = texture2D(noisetex, noisePos.xz * 0.0025 + floor(noisePos.y * 0.25) * 0.25).r;
                    float n3db = texture2D(noisetex, noisePos.xz * 0.0025 + floor(noisePos.y * 0.25 + 1.0) * 0.25).r;

                    float cloudyNoise = mix(n3da, n3db, fract(noisePos.y * 0.25));
                          cloudyNoise = max(cloudyNoise * cloudyNoise * cloudyNoise, 0.0);
                    lpvFogSample *= cloudyNoise;
                    #endif
                }
            }
            #endif

            //Nether Smoke
            #ifdef NETHER_SMOKE
            if (lWorldPos < 128.0) {
                float fogSample = getNetherFogSample(rayPos * NETHER_SMOKE_FREQUENCY + wind2 * NETHER_SMOKE_SPEED);
                vlSample += netherColSqrt * netherColSqrt * netherColSqrt * netherColSqrt * fogSample * 64.0;
            }
            #endif

            //Translucency Blending
            if (linearZ0 < currentDist) {
                vlSample *= translucent;
                lpvFogSample *= translucent;
            }

            //Accumulate samples
            vl += vlSample * currentSampleIntensityVL * vlIntensity;
            vl += lpvFogSample * currentSampleIntensityLPV * lpvFogIntensity;
        }
        vl *= totalVisibility;
    }
}