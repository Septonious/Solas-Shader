vec4 getWaterFog(vec3 viewPos) {
    float neBS = clamp(eBS + 0.25, 0.5, 1.0);
    float fog = length(viewPos) / waterFogRange;
    fog = 1.0 - exp(-2.0 * fog);

    vec3 waterFogColor = waterColor.rgb * waterColor.rgb;
         #ifdef OVERWORLD
         waterFogColor *= (0.125 + timeBrightness * 0.875) * 0.5;

         if (isEyeInWater == 1) {
            float VoL = dot(normalize(viewPos), sunVec);
            float glare = clamp((VoL) * 0.5 + 0.5, 0.0, 1.0);
            glare = 0.01 / (1.0 - 0.99 * glare) - 0.01;
            waterFogColor *= 1.0 + glare * 32.0;
         }

         waterFogColor = mix(waterFogColor, weatherCol.rgb * 0.0125, rainStrength * 0.25);
         #endif

         waterFogColor *= neBS;
         waterFogColor *= 1.0 - blindFactor;

		 #if MC_VERSION >= 11900
		 waterFogColor *= 1.0 - darknessFactor;
		 #endif

    return vec4(waterFogColor, fog);
}