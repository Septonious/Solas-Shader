//1.19 Darkness Fog
#if MC_VERSION >= 11900
void getDarknessFog(inout vec3 color, float lViewPos) {
	float fog = lViewPos * (darknessFactor * 0.01);
		  fog = (1.0 - exp(-fog)) * darknessFactor;

	color = mix(color, vec3(0.0), fog);
}
#endif

//Blindness Fog
void getBlindFog(inout vec3 color, float lViewPos) {
	float fog = lViewPos * (blindFactor * 0.1);
		  fog = (1.0 - exp(-4.0 * pow3(fog))) * blindFactor;

	color = mix(color, vec3(0.0), fog);
}

//Powder Snow / Lava Fog
vec3 densefogCol[2] = vec3[2](
	vec3(1.0, 0.18, 0.02),
	vec3(0.05, 0.07, 0.12)
);

void getDenseFog(inout vec3 color, float lViewPos) {
	float fog = lViewPos * (0.15 + float(isEyeInWater == 3) * 0.5);
		  fog = 1.0 - exp(-2.0 * pow2(fog));

	color = mix(color, densefogCol[isEyeInWater - 2], fog);
}

//Normal Fog
#ifndef END
void getNormalFog(inout vec3 color, in vec3 worldPos, in vec3 atmosphereColor, in float lViewPos, in float lWorldPos) {
    #if defined DISTANT_HORIZONS && (defined DEFERRED || defined DH_WATER || defined GBUFFERS_WATER)
    float farPlane = dhRenderDistance - 128.0;
    #else
    float farPlane = far;
    #endif

	//Overworld Fog
	#ifdef OVERWORLD
    float fogDistanceFactor = mix(50.0, FOG_DISTANCE * (0.7 + timeBrightness * 0.3), caveFactor);
	float fogDistance = min(192.0 / farPlane, 1.0) * (100.0 / fogDistanceFactor);
	float fogVariableHeight = FOG_HEIGHT;
		  fogVariableHeight += texture2D(noisetex, (worldPos.xz + cameraPosition.xz + frameCounter * 0.06 * VC_SPEED) * 0.00003).b * 50.0 - 50.0;
	float fogAltitudeFactor = clamp(exp2(-max(cameraPosition.y - fogVariableHeight, 0.0) / exp2(FOG_HEIGHT_FALLOFF)), 0.0, 1.0);
	float fogAltitude = clamp(exp2(-max(worldPos.y + cameraPosition.y - fogVariableHeight, 0.0) / exp2(FOG_HEIGHT_FALLOFF)), 0.0, 1.0);
	float fogDensity = FOG_DENSITY * (1.0 - pow(eBS, 0.1) * timeBrightness * 0.5);

	#if MC_VERSION >= 12104
	fogDensity = mix(fogDensity, 6.0, isPaleGarden);
	fogDistance *= 1.0 - isPaleGarden * 0.75;
	#endif

    float fog = 1.0 - exp(-(0.0075 + wetness * caveFactor * 0.0025) * lViewPos * fogDistance);
		  fog = clamp(fog * fogDensity * fogAltitude, 0.0, 1.0);

	vec3 fogCol = mix(caveMinLightCol * atmosphereColor, mix(atmosphereColor, ambientColor, 0.25) * 0.85, caveFactor);

	//Distant Fade
	#ifdef DISTANT_FADE
	if (isEyeInWater < 0.5) {
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

    //Mixing Colors depending on depth
	#if !defined NETHER && defined DEFERRED && !defined DISTANT_HORIZONS
    float zMixer = float(texture2D(depthtex1, texCoord).r < 1.0);

	#if MC_VERSION >= 12104
		  zMixer = mix(zMixer, 1.0, isPaleGarden);
	#endif
	      zMixer = clamp(zMixer, 0.0, 1.0);

	fog *= zMixer;
	#endif

	color = mix(color, fogCol, fog);
}
#endif

void Fog(inout vec3 color, in vec3 viewPos, in vec3 worldPos, in vec3 atmosphereColor) {
    float lViewPos = length(viewPos.xz);
    float lWorldPos = length(worldPos.xz);

	if (isEyeInWater < 1) {
		#ifndef END
        getNormalFog(color, worldPos, atmosphereColor, lViewPos, lWorldPos);
		#endif
    } else if (1 < isEyeInWater) {
        getDenseFog(color, lViewPos);
    }
	if (0 < blindFactor) getBlindFog(color, lViewPos);

	#if MC_VERSION >= 11900
	if (0 < darknessFactor) getDarknessFog(color, lViewPos);
	#endif
}