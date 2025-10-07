vec4 getWaterFog(inout vec3 color, vec3 viewPos) {
	float absorption = length(viewPos) * 0.01 * WATER_FOG_DENSITY;
		  absorption = 1.0 - exp(WATER_FOG_EXPONENT * 2.0 * absorption);
	color.r *= 1.0 - absorption;
	color.g *= 1.0 - absorption * absorption * 0.5;
	color *= 1.0 - absorption * absorption * absorption * 0.5;

	float fog = length(viewPos) * 0.005 * WATER_FOG_DENSITY;
		  fog = 1.0 - exp(WATER_FOG_EXPONENT * fog);

	vec3 waterFogColor = waterColor;

	#ifdef OVERWORLD
		 waterFogColor = mix(waterFogColor, weatherCol.rgb * 0.25, wetness * 0.25);

	if (isEyeInWater == 1) {
		waterFogColor *= 0.15 + sunVisibility * 0.25;

		if (caveFactor > 0.0) {
			vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

			float VoL = dot(normalize(viewPos), lightVec);
			float glare = clamp(VoL * 0.5 + 0.5, 0.0, 1.0) * shadowFade; 
				glare = 0.03 / (1.0 - 0.97 * glare) - 0.03;
			waterFogColor *= 1.0 + (0.5 + glare * 64.0 * timeBrightness) * caveFactor;
		}

		waterFogColor *= 0.25 + eBS * 0.75;
	}
	#endif

	waterFogColor *= 1.0 - pow(fog, 0.25) * 0.75;

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