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

	color = mix(color, densefogCol[isEyeInWater - 2], fog);
}

//Normal Fog
void getNormalFog(inout vec3 color, in vec3 atmosphereColor, in vec3 viewPos, in vec3 worldPos, in float lViewPos, in float lWorldPos, in float z0) {
    #if defined DISTANT_HORIZONS && (defined DEFERRED || defined DH_WATER || defined GBUFFERS_WATER)
    float farPlane = dhRenderDistance * 0.6;
    #else
    float farPlane = far;
    #endif

	//Overworld Fog
	#ifdef OVERWORLD
	vec3 fogPos = worldPos + cameraPosition;
	float noise = texture2D(noisetex, (fogPos.xz + fogPos.y) * 0.0005 + frameCounter * 0.000025).r;
          noise *= noise;
    float distanceFactor = 50.0 * (0.5 + timeBrightness * 0.75) + FOG_DISTANCE * (0.75 + caveFactor * 0.25) - wetness * 25.0;
	float distanceMult = max(256.0 / farPlane, 2.0) * (100.0 / distanceFactor);
	float altitudeFactor = FOG_HEIGHT + noise * 10.0 + timeBrightness * 35.0 + moonVisibility * 20.0;
	float altitude = exp2(-max(worldPos.y + cameraPosition.y - altitudeFactor, 0.0) / exp2(FOG_HEIGHT_FALLOFF + moonVisibility + timeBrightness + wetness));
		  //altitude = mix(1.0, altitude, clamp((cameraPosition.y - altitude) / altitude, 0.0, 1.0));
	float density = FOG_DENSITY * (1.0 + sunVisibility * (1.0 - timeBrightness) * 0.75 + moonVisibility * 0.25) * (0.5 + noise);
		  density += isLushCaves * 0.35 + isDesert * 0.25;

	#if MC_VERSION >= 12104
    density += isPaleGarden;
	#endif

    float fog = 1.0 - exp(-0.005 * lViewPos * distanceMult);
		  fog = clamp(fog * density * altitude, 0.0, 1.0);

    vec3 nSkyColor = 0.75 * sqrt(normalize(skyColor + 0.000001)) * mix(vec3(1.0), biomeColor, sunVisibility * isSpecificBiome);
	vec3 fogCol = mix(caveMinLightCol * (1.0 - isCaveBiome) + caveBiomeColor,
                   mix(atmosphereColor, nSkyColor, sunVisibility * min((1.0 - wetness) * (1.0 - fog) + 0.25, 1.0)),
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

		float vanillaFog = 1.0 - (farPlane - (fogFactor + fogOffset)) * 8.0 / (4.0 * farPlane);
			  vanillaFog = clamp(vanillaFog * vanillaFog * vanillaFog, 0.0, 1.0) * caveFactor;
	
		if (0.0 < vanillaFog){
			fogCol *= fog;
			fog = mix(fog, 1.0, vanillaFog);

			if (0.0 < fog) fogCol = mix(fogCol, atmosphereColor, vanillaFog) / fog;
		}
	}
	#endif
	#endif

	//Nether Fog
	#ifdef NETHER
	float fog = lViewPos * 0.004;
	#ifdef DISTANT_FADE
	      fog += 6.0 * pow4(lWorldPos / farPlane);
	#endif
	      fog = 1.0 - exp(-fog);

	vec3 fogCol = netherColSqrt.rgb * 0.25;
	#endif

	//End fog
	#ifdef END
	float VoU = dot(normalize(viewPos), upVec);
	float density = pow4(1.0 - abs(VoU));
		  density *= 1.0 - clamp((cameraPosition.y - 100.0) * 0.01, 0.0, 1.0);

	float fog = 1.0 - exp(-0.0001 * lViewPos);
		  fog = clamp(fog * density, 0.0, 1.0);

	vec3 fogCol = vec3(0.9, 1.0, 0.8) * endLightCol;
	#endif

    //Mixing Colors depending on depth
	#if !defined NETHER && !defined END && defined DEFERRED && !defined DISTANT_HORIZONS
    float zMixer = float(z0 < 1.0);

	#if MC_VERSION >= 12104 && defined OVERWORLD
		  zMixer = mix(zMixer, 1.0, isPaleGarden);
	#endif
	      zMixer = clamp(zMixer, 0.0, 1.0);

	fog *= zMixer;
	#endif

	color = mix(color, fogCol, fog);
}

void Fog(inout vec3 color, in vec3 viewPos, in vec3 worldPos, in vec3 atmosphereColor, in float z0) {
    float lViewPos = length(viewPos.xz);
    float lWorldPos = length(worldPos.xz);

	if (isEyeInWater < 1) {
        getNormalFog(color, atmosphereColor, viewPos, worldPos, lViewPos, lWorldPos, z0);
    } else if (isEyeInWater > 1) {
        getDenseFog(color, lViewPos);
    }
	if (blindFactor > 0.0) getBlindFog(color, lViewPos);

	#if MC_VERSION >= 11900
	if (darknessFactor > 0.0) getDarknessFog(color, lViewPos);
	#endif
}