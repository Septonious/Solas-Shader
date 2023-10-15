vec4 getWaterFog(vec3 viewPos) {
    float fog = length(viewPos) / waterFogRange;
    fog = 1.0 - exp(-4.0 * fog);

    vec3 waterFogColor = mix(mix(waterColor * waterColor, fogColor * fogColor, 0.4), weatherCol.rgb * 0.25, wetness * 0.25);
         #ifdef OVERWORLD
         waterFogColor *= (0.25 + timeBrightness * 0.50) * 0.5;

         if (isEyeInWater == 1) {
            vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

            float VoL = dot(normalize(viewPos), lightVec) * shadowFade;
            float glare = clamp(VoL * 0.5 + 0.5, 0.0, 1.0);
                  glare = 0.01 / (1.0 - 0.99 * glare) - 0.01;
            waterFogColor *= 1.0 + glare * 24.0 * eBS;
         }
         #endif

         waterFogColor *= clamp(eBS, 0.25, 1.0);
         waterFogColor *= 1.0 - blindFactor;

		 #if MC_VERSION >= 11900
		 waterFogColor *= 1.0 - darknessFactor;
		 #endif

    return vec4(waterFogColor, fog);
}