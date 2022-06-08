#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

void getNormalFog(inout vec3 color, vec3 viewPos, in vec3 skyColor) {
	vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos;

	float lViewPos = length(viewPos);

	#ifdef DISTANT_FADE
	float lWorldPos = length(worldPos.xz);
    #endif
	
	//Overworld Fog
	#ifdef OVERWORLD
	float density = FOG_DENSITY * (1.0 + pow4(rainStrength) * 7.0);
	float fog = lViewPos * density * 0.001;
	fog = 1.0 - exp(-3.0 * fog);

	//Fog Altitude
	float worldHeightFactor = clamp((worldPos.y + cameraPosition.y) * 0.001 * FOG_HEIGHT, 0.0, 1.0);
	fog *= 1.0 - worldHeightFactor;

	vec3 dayFogColor = vec3(SKY_R, SKY_G, SKY_B) / 255.0 * SKY_I;
    vec3 fogColor = mix(dayFogColor, skyColor, 0.5 + clamp(rainStrength + moonVisibility, 0.0, 0.5));

	//Distant Fade
	#ifdef DISTANT_FADE
	if (isEyeInWater == 0) {
		float vanillaFog = pow8(lViewPos * FOG_DENSITY * 0.0025) + pow8(lWorldPos / far);
		vanillaFog = clamp(vanillaFog, 0.0, 1.0);

		fogColor *= fog;
				
		fog = mix(fog, 1.0, vanillaFog);
		if (fog > 0.0) fogColor = mix(fogColor, skyColor, vanillaFog) / fog;
	}
	#endif

	fogColor = mix(minLightCol * 0.25, fogColor, ug);
	#endif

	//Nether Fog
	#ifdef NETHER
	vec3 fogColor = netherCol.rgb * 0.15;
	float fog = pow(lViewPos * FOG_DENSITY * 0.0025, 1.5);

	#ifdef DISTANT_FADE
	fog += 6.0 * pow4(lWorldPos * 1.5 / far);
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
	fog = (1.0 - exp(-4.0 * fog * fog * fog));

	vec3 denseFogColor0 = denseFogColor[isEyeInWater - 2];

	#ifdef OVERWORLD
	denseFogColor0 *- clamp(timeBrightness, 0.01, 0.9);
	#endif

	color = mix(color, denseFogColor0, fog);
}

void Fog(inout vec3 color, in vec3 viewPos, in vec3 skyColor) {
	getNormalFog(color, viewPos, skyColor);
	if (isEyeInWater > 1) getDenseFog(color, viewPos);
	if (blindFactor > 0.0) getBlindFog(color, viewPos);
	#if MC_VERSION >= 11900
	if (darknessFactor > 0.0) getDarknessFog(color, viewPos);
	#endif
}