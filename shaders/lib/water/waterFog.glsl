vec4 getWaterFog(vec3 viewPos, float densityMultiplier) {
	float fog = length(viewPos) * 0.01;
		  fog = 1.0 - exp(WATER_FOG_EXPONENT * fog * densityMultiplier);

	vec3 waterFogColor = mix(mix(waterColor, normalize(fogColor + 0.00001) * 0.5, 0.25), weatherCol.rgb * 0.25, wetness * 0.25);

	#ifdef OVERWORLD
		if (isEyeInWater == 1) {
			waterFogColor *= 0.1 + sunVisibility * 0.4;
			vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

			float VoL = dot(normalize(viewPos), lightVec) * shadowFade;
			float glare = clamp(VoL * 0.5 + 0.5, 0.0, 1.0);
				  glare = 0.01 / (1.0 - 0.99 * glare) - 0.01;
			waterFogColor *= (0.5 + 0.5 * eBS) + glare * 16.0 * timeBrightness * eBS;
		}
	#endif

	waterFogColor *= 1.0 - blindFactor;

	#if MC_VERSION >= 11900
	waterFogColor *= 1.0 - darknessFactor;
	#endif

	return vec4(waterFogColor, fog);
}