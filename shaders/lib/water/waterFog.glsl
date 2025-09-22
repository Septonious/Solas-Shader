vec4 getWaterFog(vec3 viewPos) {
	float fog = length(viewPos) * 0.01 * WATER_FOG_DENSITY;
		  fog = 1.0 - exp(WATER_FOG_EXPONENT * fog);

	vec3 waterFogColor = mix(waterColor, normalize(fogColor + 0.00001) * 0.5, 0.25);

	#ifdef OVERWORLD
	waterFogColor = mix(waterFogColor, weatherCol.rgb * 0.25, wetness * 0.25);

	if (isEyeInWater == 1) {
		waterFogColor *= 0.075;

		if (eBS > 0.0) {
			vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

			float VoL = dot(normalize(viewPos), lightVec);
			float glare = clamp(VoL * 0.5 + 0.5, 0.0, 1.0) * shadowFade; 
				glare = 0.03 / (1.0 - 0.97 * glare) - 0.03;
			waterFogColor *= 1.0 + (0.5 + glare * 32.0 * timeBrightness) * eBS;
		}
	}

	waterFogColor *= 0.5 + timeBrightness * 0.5;
    waterFogColor *= 1.0 - wetness * 0.25;
	waterFogColor *= 0.4 + eBS * 0.6;
	#endif

	//Light absorption
	waterFogColor *= 0.3 + (1.0 - fog) * 0.5;

    //Dynamic Hand Lighting
    #ifdef DYNAMIC_HANDLIGHT
    waterFogColor += getHandLightColor(waterFogColor, viewPos);
    #endif

	waterFogColor *= 1.0 - blindFactor;

	#if MC_VERSION >= 11900
	waterFogColor *= 1.0 - darknessFactor;
	#endif

	return vec4(waterFogColor, fog);
}