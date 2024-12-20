//Pale Garden uniform for fog//
#if MC_VERSION >= 12100
uniform float isPaleGarden;
#endif

//Fog that appears when you have a darkness effect
#if MC_VERSION >= 11900
void getDarknessFog(inout vec3 color, vec3 viewPos) {
	float fog = length(viewPos) * (darknessFactor * 0.01);
		  fog = (1.0 - exp(-fog)) * darknessFactor;

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
vec3 densefogCol[2] = vec3[2](
	vec3(1.0, 0.18, 0.02),
	vec3(0.05, 0.07, 0.12)
);

void getDenseFog(inout vec3 color, vec3 viewPos) {
	float fog = length(viewPos) * (0.15 + float(isEyeInWater == 3) * 0.5);
		  fog = 1.0 - exp(-2.0 * pow2(fog));

	color = mix(color, densefogCol[isEyeInWater - 2], fog);
}

#if defined DISTANT_HORIZONS && (defined DEFERRED || defined DH_WATER || defined GBUFFERS_WATER)
void getNormalFog(inout vec3 color, vec3 viewPos, in vec3 worldPos, in vec3 atmosphereColor) {
	float lViewPos = length(viewPos);
	float lWorldPos = length(worldPos.xz);

	//Overworld Fog
	#ifdef OVERWORLD
	float eBS01 = pow(eBS, 0.1);
	float wetnessCave = wetness * caveFactor;
	float distanceFactor = mix(65.0, FOG_DISTANCE * (0.6 + timeBrightness * 0.4), caveFactor);
	float cameraAltitude = clamp(exp2(-max(cameraPosition.y - FOG_HEIGHT, 0.0) / exp2(FOG_HEIGHT_FALLOFF)), 0.0, 1.0);
	float fogAltitude = clamp(exp2(-max(worldPos.y + cameraPosition.y - FOG_HEIGHT, 0.0) / exp2(FOG_HEIGHT_FALLOFF)), 0.0, 1.0);
	float fogDistance = min(192.0 / dhFarPlane, 1.0) * (100.0 / distanceFactor);
	float fogDensity = FOG_DENSITY * (2.0 - caveFactor) * (1.0 - eBS01 * timeBrightness * 0.5);

	#if MC_VERSION >= 12100
	fogDensity = mix(fogDensity, 6.0, isPaleGarden);
	fogDistance *= 1.0 - isPaleGarden * 0.75;
	#endif

    float fog = 1.0 - exp(-pow(lViewPos * (0.001 - 0.00075 * wetnessCave), 2.0 - wetnessCave) * lViewPos * fogDistance);
          fog *= fogDensity * fogAltitude;
		  fog = clamp(fog, 0.0, 1.0);

    vec3 fogCol = atmosphereColor;
		 fogCol = mix(caveMinLightCol * fog, fogCol, caveFactor);

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

		float vanillaFog = 1.0 - (dhFarPlane - (fogFactor + fogOffset)) * 8.0 / (4.0 * dhFarPlane);
			  vanillaFog = clamp(pow3(vanillaFog), 0.0, 1.0) * caveFactor;
	
		if (vanillaFog > 0.0){
			fogCol *= fog;
			fog = mix(fog, 1.0, vanillaFog);

			if (fog > 0.0) fogCol = mix(fogCol, atmosphereColor, vanillaFog) / fog;
		}
	}
	#endif
	#endif

	//Nether Fog
	#ifdef NETHER
	float fog = lViewPos * 0.004;

	#ifdef DISTANT_FADE
	fog += 6.0 * pow4(lWorldPos / dhFarPlane);
	#endif

	fog = 1.0 - exp(-fog);

	vec3 fogCol = netherColSqrt.rgb * 0.25;
	#endif

	#ifdef END
	float fog = 2.0 * pow4(lWorldPos / dhFarPlane);

	fog = 1.0 - exp(-fog);

	vec3 fogCol = atmosphereColor;
	#endif

	#ifndef NETHER
	#ifdef DEFERRED
	float zMixer = float(texture2D(dhDepthTex0, texCoord).r < 1.0);
	#if MC_VERSION >= 12100
		  zMixer = mix(zMixer, 1.0, isPaleGarden);
	#endif
	#ifdef FOG_COVER_EVERYTHING
	zMixer = mix(zMixer, 1.0, cameraAltitude * cameraAltitude * 0.5);
	#endif
	fog *= zMixer;
	#endif
	#endif

	color = mix(color, fogCol, fog);
}
#else
void getNormalFog(inout vec3 color, vec3 viewPos, in vec3 worldPos, in vec3 atmosphereColor) {
	float lViewPos = length(viewPos);
	float lWorldPos = length(worldPos.xz);

	//Overworld Fog
	#ifdef OVERWORLD
	float eBS01 = pow(eBS, 0.1);
	float wetnessCave = wetness * caveFactor;
	float distanceFactor = mix(65.0, FOG_DISTANCE * (0.6 + timeBrightness * 0.4), caveFactor);
	float cameraAltitude = clamp(exp2(-max(cameraPosition.y - FOG_HEIGHT, 0.0) / exp2(FOG_HEIGHT_FALLOFF)), 0.0, 1.0);
	float fogAltitude = clamp(exp2(-max(worldPos.y + cameraPosition.y - FOG_HEIGHT, 0.0) / exp2(FOG_HEIGHT_FALLOFF)), 0.0, 1.0);
	float fogDistance = min(192.0 / far, 1.0) * (100.0 / distanceFactor);
	float fogDensity = FOG_DENSITY * (2.0 - caveFactor) * (1.0 - eBS01 * timeBrightness * 0.5);

	#if MC_VERSION >= 12100
	fogDensity = mix(fogDensity, 6.0, isPaleGarden);
	fogDistance *= 1.0 - isPaleGarden * 0.75;
	#endif

    float fog = 1.0 - exp(-(0.0075 + wetnessCave * 0.0025) * lViewPos * fogDistance);
          fog *= fogDensity * fogAltitude;
		  fog = clamp(fog, 0.0, 1.0);

    vec3 fogCol = atmosphereColor;
		 fogCol = mix(caveMinLightCol * fog, fogCol, caveFactor);

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
			  vanillaFog = clamp(pow3(vanillaFog), 0.0, 1.0) * caveFactor;
	
		if (vanillaFog > 0.0){
			fogCol *= fog;
			fog = mix(fog, 1.0, vanillaFog);

			if (fog > 0.0) fogCol = mix(fogCol, atmosphereColor, vanillaFog) / fog;
		}
	}
	#endif
	#endif

	//Nether Fog
	#ifdef NETHER
	float fog = lViewPos * 0.004;

	#ifdef DISTANT_FADE
	fog += 6.0 * pow4(lWorldPos / far);
	#endif

	fog = 1.0 - exp(-fog);

	vec3 fogCol = netherColSqrt.rgb * 0.25;
	#endif

	#ifdef END
	float fog = 2.0 * pow4(lWorldPos / far);

	fog = 1.0 - exp(-fog);

	vec3 fogCol = atmosphereColor;
	#endif

	#ifndef NETHER
	#ifdef DEFERRED
	float zMixer = float(texture2D(depthtex1, texCoord).r < 1.0);
	#if MC_VERSION >= 12100
		  zMixer = mix(zMixer, 1.0, isPaleGarden);
	#endif
	#ifdef FOG_COVER_EVERYTHING
	zMixer = mix(zMixer, 1.0, cameraAltitude * cameraAltitude * 0.5);
	#endif
	zMixer = clamp(zMixer, 0.0, 1.0);
	fog *= zMixer;
	#endif
	#endif

	color = mix(color, fogCol, fog);
}
#endif

void Fog(inout vec3 color, in vec3 viewPos, in vec3 worldPos, in vec3 atmosphereColor) {
	if (isEyeInWater < 1) getNormalFog(color, viewPos, worldPos, atmosphereColor);
	if (isEyeInWater > 1) getDenseFog(color, viewPos);
	if (blindFactor > 0.0) getBlindFog(color, viewPos);

	#if MC_VERSION >= 11900
	if (darknessFactor > 0.0) getDarknessFog(color, viewPos);
	#endif
}