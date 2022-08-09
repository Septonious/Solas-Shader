vec4 getWaterFog(vec3 viewPos) {
    float clampEyeBrightness = clamp(sqrt(eBS), 0.5, 1.0);
    float fog = length(viewPos) / waterFogRange;
    fog = 1.0 - exp(-9.0 * fog);

    vec3 waterFogColor = waterColor.rgb * waterColor.rgb;
         #ifdef OVERWORLD
         waterFogColor = mix(mix(waterFogColor, waterFogColor, eBS), fogColor * 0.4, 0.4) * (0.125 + timeBrightness * 0.875);

         if (isEyeInWater == 1) {
            float VoS = clamp(dot(normalize(viewPos), lightVec), 0.0, 1.0);
            waterFogColor *= 1.0 + pow8(VoS) + pow4(VoS);
         }

         waterFogColor = mix(waterFogColor, weatherCol.rgb * 0.0125, rainStrength * 0.25);
         #endif

         waterFogColor *= clampEyeBrightness;
         waterFogColor *= 1.0 - blindFactor;

		 #if MC_VERSION >= 11900
		 waterFogColor *= 1.0 - darknessFactor;
		 #endif

    return vec4(waterFogColor, fog);
}