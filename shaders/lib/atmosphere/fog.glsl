//1.19 Darkness Fog
#if MC_VERSION >= 11900
void getDarknessFog(inout vec3 color, float lViewPos) {
	float fog = lViewPos * darknessFactor * 0.01;
		  fog = (1.0 - exp(-fog)) * darknessFactor;

    color *= 1.0 - fog;
}
#endif

//Blindness Fog
void getBlindFog(inout vec3 color, float lViewPos) {
	float fog = lViewPos * blindFactor * 0.1;
		  fog = (1.0 - exp(-4.0 * fog * fog * fog)) * blindFactor;

	color *= 1.0 - fog;
}

//Powder Snow / Lava Fog
vec3 densefogCol[2] = vec3[2](
	vec3(1.0, 0.18, 0.02),
	vec3(0.05, 0.07, 0.12)
);

void getDenseFog(inout vec3 color, float lViewPos) {
	float fog = lViewPos * (0.15 + float(isEyeInWater == 3) * 0.5);
		  fog = 1.0 - exp(-2.0 * fog * fog);

	color = fmix(color, densefogCol[isEyeInWater - 2], fog);
}

//Normal Fog
void getNormalFog(inout vec3 color, in vec3 atmosphereColor, in vec3 viewPos, in vec3 worldPos, in float lViewPos, in float lWorldPos, in float z0) {
    float farPlane = far;

    #ifdef VOXY
            farPlane = max(farPlane, vxRenderDistance * 16.0);
    #endif

    #ifdef DISTANT_HORIZONS
            farPlane = max(farPlane, float(dhRenderDistance));
    #endif

	//Overworld Fog
	#ifdef OVERWORLD
	vec3 fogPos = worldPos + cameraPosition;
	float noise = texture2D(noisetex, (vec2(fogPos.x, fogPos.y * 0.5) + vec2(fogPos.z, fogPos.y * 0.5)) * 0.0005 + frameCounter * 0.00001).r;
            noise *= noise;
    float distanceFactor = 50.0 * (0.5 + timeBrightness * 0.75) + FOG_DISTANCE * (0.75 + caveFactor * 0.25) - wetness * 25.0;
	float distanceMult = max(256.0 / farPlane, 2.0) * (100.0 / distanceFactor);
	float altitudeFactor = FOG_HEIGHT + noise * 10.0 + timeBrightness * 25.0 - isJungle * 15.0;
	float altitude = 0.25 + exp2(-max(worldPos.y + cameraPosition.y - altitudeFactor, 0.0) / exp2(FOG_HEIGHT_FALLOFF + moonVisibility + timeBrightness + wetness - isJungle - isSwamp));
		  //altitude = fmix(1.0, altitude, clamp((cameraPosition.y - altitude) / altitude, 0.0, 1.0));
	float density = FOG_DENSITY * (1.0 + (sunVisibility - timeBrightness) * 0.25 + moonVisibility * 0.5) * (0.5 + noise);
		  density += isLushCaves * 0.25 + (isDesert * 0.15 + isSwamp * 0.20 + isJungle * 0.35);

	#if MC_VERSION >= 12104
    	  density += isPaleGarden * 0.5;
	#endif

    float fog = 1.0 - exp(-0.005 * lViewPos * distanceMult);
		  fog = clamp(fog * density * altitude, 0.0, 1.0);

    vec3 nSkyColor = 0.75 * sqrt(normalize(skyColor + 0.000001)) * fmix(vec3(1.0), biomeColor, sunVisibility * isSpecificBiome);
	vec3 fogCol = fmix(caveMinLightCol * (1.0 - isCaveBiome) + caveBiomeColor,
                   fmix(pow(atmosphereColor, vec3(1.0 - sunVisibility * 0.5)), nSkyColor, sunVisibility * min((1.0 - wetness) * (1.0 - fog), 1.0)) * 0.75,
                   caveFactor);

	//Distant Fade
	#ifdef DISTANT_FADE
	if (isEyeInWater == 0) {
		#if MC_VERSION >= 11800
		const float fogOffset = 0.0;
		#else
		const float fogOffset = 12.0;
		#endif

		#if DISTANT_FADE_STYLE == 0
		float fogFactor = lWorldPos;
		#else
		float fogFactor = lViewPos;
		#endif

        float distancePow = 4.0;
        #if defined DISTANT_HORIZONS || defined VOXY
                distancePow -= 3.0;
        #endif

		float vanillaFog = 1.0 - (farPlane - (fogFactor + fogOffset)) / farPlane;
		        vanillaFog = clamp(pow(vanillaFog, distancePow), 0.0, 1.0) * caveFactor;
	
		if (vanillaFog > 0.0){
			fogCol *= fog;
			fog = fmix(fog, 1.0, vanillaFog);

			if (0.0 < fog) fogCol = fmix(fogCol, atmosphereColor, vanillaFog) / fog;
		}
	}
	#endif
	#endif

	//Nether Fog
	#ifdef NETHER
	float fog = lViewPos * 0.005;
	#ifdef DISTANT_FADE
	      fog += 6.0 * pow4(lWorldPos / farPlane);
	#endif
	      fog = 1.0 - exp(-fog);

	vec3 fogCol = netherColSqrt.rgb * 0.25;
	#endif

	//End fog
	#ifdef END
    vec3 wpos = ToWorld(viewPos);
    vec3 nWorldPos = normalize(wpos);
    nWorldPos.y += nWorldPos.x * END_ANGLE;

    #ifdef END_67
    if (frameCounter < 500) {
        nWorldPos.y += nWorldPos.x * 0.5 * sin(frameTimeCounter * 8);
    }
    #endif

	#ifdef END_TIME_TILT
		nWorldPos.y += nWorldPos.x * min(0.025 * frameTimeCounter, 1.0);
	#endif

	float density = pow4(1.0 - abs(nWorldPos.y));
		  density *= 1.0 - clamp((cameraPosition.y - 100.0) * 0.01, 0.0, 1.0);

	float fog = 1.0 - exp(-0.0001 * length(wpos));
		  fog = clamp(fog * density, 0.0, 1.0);

	vec3 fogCol = vec3(1.0, 1.0, 0.75) * endLightColSqrt;
	#endif

    //Mixing Colors depending on depth
	#if !defined NETHER && !defined END && defined DEFERRED && !defined DISTANT_HORIZONS
    float zMixer = float(z0 < 1.0);

	#if MC_VERSION >= 12104 && defined OVERWORLD
		  zMixer = fmix(zMixer, 1.0, isPaleGarden);
	#endif
	      zMixer = clamp(zMixer, 0.0, 1.0);

	fog *= zMixer;
	#endif

	color = fmix(color, fogCol, fog);
}

void Fog(inout vec3 color, in vec3 viewPos, in vec3 atmosphereColor, in float z0) {
	vec4 worldPos = gbufferModelViewInverse * vec4(viewPos, 1.0);
	        worldPos.xyz /= worldPos.w;

    float lViewPos = length(viewPos.xz);
    float lWorldPos = length(worldPos.xz);

	if (isEyeInWater < 1) {
        getNormalFog(color, atmosphereColor, viewPos, worldPos.xyz, lViewPos, lWorldPos, z0);
    } else if (isEyeInWater > 1) {
        getDenseFog(color, lViewPos);
    }
	if (blindFactor > 0.0) getBlindFog(color, lViewPos);

	#if MC_VERSION >= 11900
	if (darknessFactor > 0.0) getDarknessFog(color, lViewPos);
	#endif
}