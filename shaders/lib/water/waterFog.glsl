vec4 getWaterFog(vec3 viewPos, float densityMultiplier) {
	float fog = pow(length(viewPos), 2.0) * 0.01;
		  fog = 1.0 - exp(WATER_FOG_EXPONENT * fog * densityMultiplier);

	#ifdef OVERWORLD
	vec3 waterFogColor = mix(mix(waterColor, normalize(fogColor + 0.00001) * 0.5, 0.25), weatherCol.rgb * 0.25, wetness * 0.25);

	if (isEyeInWater == 1) {
		waterFogColor *= 0.1 + sunVisibility * 0.4;
		vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

		float VoL = dot(normalize(viewPos), lightVec);
		float glare = clamp(VoL * 0.5 + 0.5, 0.0, 1.0) * shadowFade; 
			  glare = 0.03 / (1.0 - 0.97 * glare) - 0.03;
		waterFogColor *= 0.5 + (0.5 + glare * 8.0 * timeBrightness) * eBS;
	}
	#else
	vec3 waterFogColor = mix(waterColor, normalize(fogColor + 0.00001) * 0.5, 0.25);
	#endif

    //Dynamic Hand Lighting
    #ifdef DYNAMIC_HANDLIGHT
    getHandLightColor(waterFogColor, vec3(1.0), viewPos);
    #endif

	waterFogColor *= 1.0 - blindFactor;

	#if MC_VERSION >= 11900
	waterFogColor *= 1.0 - darknessFactor;
	#endif

	return vec4(waterFogColor, fog);
}