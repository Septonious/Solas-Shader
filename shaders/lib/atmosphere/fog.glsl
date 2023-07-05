void getNormalFog(inout vec3 color, vec3 viewPos, in vec3 worldPos, in vec3 atmosphereColor) {
	float lViewPos = length(viewPos);

	#ifdef DISTANT_FADE
	float lWorldPos = length(worldPos.xz);
    #endif

	//Overworld Fog
	#ifdef OVERWORLD
	float fogAltitude = clamp(pow32((worldPos.y + cameraPosition.y + 1000.0 - FOG_HEIGHT) * 0.001), 0.0, 1.0);

	float fog = lViewPos * FOG_DENSITY * 0.001;
		  fog = 1.0 - exp(-(3.0 + rainStrength) * fog);
		  fog *= 1.0 - fogAltitude * mix(0.75, 0.25, rainStrength);
		  fog *= mix(1.5 - sunVisibility * 0.5, 1.0, rainStrength);
		  fog = clamp(fog, 0.0, 1.0);

	vec3 fogColor = mix(skyColor, atmosphereColor, 0.4 + clamp(fogAltitude + rainStrength + (1.0 - sunVisibility), 0.0, 0.6)) * fog;

    //Underground Fog
	fogColor = mix(caveMinLightCol * fog, fogColor, caveFactor);

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

		float vanillaFog = 1.0 - (far - (fogFactor + fogOffset)) * 8.0 / (4.0 * far);
			  vanillaFog = clamp(pow3(vanillaFog), 0.0, 1.0);
	
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
	float fog = lViewPos * 0.005;

	#ifdef DISTANT_FADE
	fog += 2.0 * pow4(lWorldPos / far);
	#endif

	fog = 1.0 - exp(-fog);

	vec3 fogColor = netherColSqrt.rgb * 0.25;
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
	float fog = length(viewPos) * (blindFactor * 0.1);
		  fog = (1.0 - exp(-4.0 * pow3(fog))) * blindFactor;

	color = mix(color, vec3(0.0), fog);
}

//Powder Snow / Lava Fog
vec3 denseFogColor[2] = vec3[2](
	vec3(1.0, 0.18, 0.02),
	vec3(0.05, 0.07, 0.12)
);

void getDenseFog(inout vec3 color, vec3 viewPos) {
	float fog = length(viewPos) * 0.5;
		  fog = 1.0 - exp(-3.0 * pow3(fog));

	color = mix(color, denseFogColor[isEyeInWater - 2], fog);
}

void Fog(inout vec3 color, in vec3 viewPos, in vec3 worldPos, in vec3 atmosphereColor) {
	if (isEyeInWater < 1) getNormalFog(color, viewPos, worldPos, atmosphereColor);
	if (isEyeInWater > 1) getDenseFog(color, viewPos);
	if (blindFactor > 0.0) getBlindFog(color, viewPos);

	#if MC_VERSION >= 11900
	if (darknessFactor > 0.0) getDarknessFog(color, viewPos);
	#endif
}