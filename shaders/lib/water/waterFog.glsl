vec4 getWaterFog(vec3 viewPos) {
	float fog = length(viewPos) * 0.01 * WATER_FOG_DENSITY;
		  fog = 1.0 - exp(WATER_FOG_EXPONENT * fog);

	vec3 waterFogColor = waterColor;

	#ifdef OVERWORLD
		 waterFogColor = mix(waterFogColor, weatherCol.rgb * 0.25, wetness * 0.25);

	if (isEyeInWater == 1) {
		waterFogColor *= 0.15 + sunVisibility * 0.8;

		if (caveFactor > 0.0) {
			vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

			float VoL = dot(normalize(viewPos), lightVec);
			float glare = clamp(VoL * 0.5 + 0.5, 0.0, 1.0) * shadowFade; 
				glare = 0.03 / (1.0 - 0.97 * glare) - 0.03;
			waterFogColor *= 1.0 + (0.5 + glare * 16.0 * timeBrightness) * caveFactor;
		}

		waterFogColor *= 0.25 + eBS * 0.75;
	}
	#endif

    //Dynamic Hand Lighting
    #ifdef DYNAMIC_HANDLIGHT
    waterFogColor += getHandLightColor(waterFogColor, viewPos);
    #endif

	waterFogColor *= 1.0 - blindFactor;

	#if MC_VERSION >= 11900
	waterFogColor *= 1.0 - darknessFactor;
	#endif

	return vec4(waterFogColor * (0.25 + (1.0 - fog) * 0.75), fog);
}