void getNormalFog(inout vec3 color, vec3 viewPos, in vec3 worldPos, in vec3 atmosphereColor) {
	float lViewPos = length(viewPos);

	#ifdef DISTANT_FADE
	float lWorldPos = length(worldPos.xz);
    #endif

	//Overworld Fog
	#ifdef OVERWORLD
	//Variables
	float fogAltitude = clamp(pow32((worldPos.y + cameraPosition.y + 1000.0 - FOG_HEIGHT) * 0.001), 0.0, 1.0);

	float fog = lViewPos * FOG_DENSITY * 0.001;
		  fog = 1.0 - exp(-mix(3.0 - fogAltitude, 5.0, rainStrength) * fog);
		  fog *= 1.0 - fogAltitude * mix(0.75 + timeBrightness * 0.25, 0.25, rainStrength);
		  fog *= mix(mix(1.0 - timeBrightness * 0.5, 1.5, sunVisibility), 1.0, rainStrength);
		  fog = clamp(fog, 0.0, 1.0);

	vec3 fogColor = mix(skyColor, atmosphereColor, 0.4 + clamp(fogAltitude + rainStrength + (1.0 - sunVisibility), 0.0, 0.6)) * fog;

    //Underground Fog
	fogColor = mix(caveMinLightCol * fog, fogColor, caveFactor);

	//Distant Fade
	#ifdef DISTANT_FADE
	if (isEyeInWater < 0.5) {
		#if MC_VERSION >= 11800
		float fogOffset = 0.0;
		#else
		float fogOffset = 12.0;
		#endif

		#if DISTANT_FADE_STYLE == 0
		float fogFactor = lWorldPos;
		#else
		float fogFactor = lViewPos;
		#endif

		float vanillaFog = 1.0 - (far - (fogFactor + fogOffset)) * 8.0 / (4.0 * far);
		vanillaFog = pow3(vanillaFog);
		vanillaFog = clamp(vanillaFog, 0.0, 1.0);
	
		if (vanillaFog > 0.0){
			fogColor *= fog;
			fog = mix(fog, 1.0, vanillaFog);
			if (fog > 0.0) fogColor = mix(fogColor, atmosphereColor, vanillaFog) / fog;
		}
	}
	#endif
	#endif

	//Nether Fog
	#ifdef NETHER
	vec3 fogColor = netherColSqrt.rgb * 0.25;
	float fog = lViewPos * 0.005;

	#ifdef DISTANT_FADE
	fog += 2.0 * pow4(lWorldPos / far);
	#endif

	fog = 1.0 - exp(-fog);
	#endif

	//We don't want fog in the End because it looks cringe
	#ifndef END
	color = mix(color, fogColor, fog);
	#endif
}

//Fog that appears when you have a darkness effect
#if MC_VERSION >= 11900
void getDarknessFog(inout vec3 color, vec3 viewPos) {
	float fog = length(viewPos) * (darknessFactor * 0.04);
	fog = (1.0 - exp(-2.0 * pow3(fog))) * darknessFactor;
	color = mix(color, vec3(0.0), fog);
}
#endif

//Fog that appears when you have a blindness effect
void getBlindFog(inout vec3 color, vec3 viewPos) {
	float fog = length(viewPos) * (blindFactor * 0.2);
	fog = (1.0 - exp(-6.0 * pow3(fog))) * blindFactor;
	color = mix(color, vec3(0.0), fog);
}

//Powder Snow / Lava Fog
#ifdef OVERWORLD
vec3 denseFogColor[2] = vec3[2](
	vec3(1.0, 0.18, 0.02),
	vec3(0.1, 0.14, 0.24) * clamp(timeBrightness, 0.3, 0.9)
);
#else
vec3 denseFogColor[2] = vec3[2](
	vec3(1.0, 0.18, 0.02),
	vec3(0.1, 0.14, 0.24)
);
#endif

void getDenseFog(inout vec3 color, vec3 viewPos) {
	float fog = length(viewPos) * 0.5;
	fog = (1.0 - exp(-3.0 * pow3(fog)));

	vec3 denseFogColor0 = denseFogColor[isEyeInWater - 2];

	color = mix(color, denseFogColor0, fog);
}

void Fog(inout vec3 color, in vec3 viewPos, in vec3 worldPos, in vec3 atmosphereColor) {
	if (isEyeInWater < 0.5) getNormalFog(color, viewPos, worldPos, atmosphereColor);
	if (isEyeInWater > 1) getDenseFog(color, viewPos);
	if (blindFactor > 0.0) getBlindFog(color, viewPos);
	#if MC_VERSION >= 11900
	if (darknessFactor > 0.0) getDarknessFog(color, viewPos);
	#endif
}