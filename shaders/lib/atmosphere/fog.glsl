void getNormalFog(inout vec3 color, vec3 viewPos, in vec3 worldPos, in vec3 colorOfTheSky) {
	float lViewPos = length(viewPos);

	#ifdef DISTANT_FADE
	float lWorldPos = length(worldPos.xz);
    #endif
	
	//Overworld Fog
	#ifdef OVERWORLD
	float fog = lViewPos * FOG_DENSITY * 0.005;
	fog = 1.0 - exp(-fog);

	//Fog Altitude
	float fogAltitude = clamp((worldPos.y + cameraPosition.y) * 0.001 * FOG_HEIGHT, 0.0, 1.0);
	fog *= 1.0 - fogAltitude * (0.5 + sunVisibility * 0.5);

	vec3 fogColor = mix(colorOfTheSky, skyColor, 0.5 * sunVisibility);
	
	//Distant Fade
	#ifdef DISTANT_FADE
	if (isEyeInWater == 0) {
		float vanillaFog = pow3(lViewPos * 0.000125);

		#if DISTANT_FADE_STYLE == 0
		vanillaFog += pow6(lWorldPos / far);
		#elif DISTANT_FADE_STYLE == 1
		vanillaFog += pow6(lViewPos / far);
		#endif

		vanillaFog = clamp(vanillaFog, 0.0, 1.0);

		fogColor *= fog;
				
		fog = mix(fog, 1.0, vanillaFog);
		if (fog > 0.0) fogColor = mix(fogColor, colorOfTheSky, vanillaFog) / fog;
	}
	#endif

	fogColor = mix(minLightCol, fogColor, ug);
	#endif

	//Nether Fog
	#ifdef NETHER
	vec3 fogColor = netherColSqrt.rgb * 0.25;
	float fog = lViewPos * FOG_DENSITY * 0.0075;

	#ifdef DISTANT_FADE
	fog += 5.0 * pow4(lWorldPos / far);
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
vec3 denseFogColor[2] = vec3[2](
	vec3(1.0, 0.2, 0.02),
	vec3(0.1, 0.14, 0.24) * 0.5
);

void getDenseFog(inout vec3 color, vec3 viewPos) {
	float fog = length(viewPos) * 0.5;
	fog = (1.0 - exp(-4.0 * pow3(fog)));

	vec3 denseFogColor0 = denseFogColor[isEyeInWater - 2];

	#ifdef OVERWORLD
	denseFogColor0 *- clamp(timeBrightness, 0.01, 0.9);
	#endif

	color = mix(color, denseFogColor0, fog);
}

void Fog(inout vec3 color, in vec3 viewPos, in vec3 worldPos, in vec3 colorOfTheSky) {
	if (isEyeInWater == 0) getNormalFog(color, viewPos, worldPos, colorOfTheSky);
	if (isEyeInWater > 1) getDenseFog(color, viewPos);
	if (blindFactor > 0.0) getBlindFog(color, viewPos);
	#if MC_VERSION >= 11900
	if (darknessFactor > 0.0) getDarknessFog(color, viewPos);
	#endif
}