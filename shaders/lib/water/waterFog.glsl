vec4 getWaterFog(vec3 viewPos) {
    float clampEyeBrightness = pow2(clamp(sqrt(eBS), 0.5, 1.0));
    #ifdef OVERWORLD
    float VoS = clamp(dot(normalize(viewPos.xyz), sunVec), 0.0, 1.0);
    #endif

    float fog = length(viewPos) / waterFogRange;
    fog = 1.0 - exp(-5.0 * fog);

    vec3 waterFogColor  = waterColor.rgb * waterColor.rgb;
         #ifdef OVERWORLD
         waterFogColor = mix(waterFogColor, waterFogColor * (1.0 + pow4(VoS) * 0.5), eBS);
         waterFogColor = mix(waterFogColor, weatherCol.rgb * 0.25, rainStrength * 0.75);
         #endif
         waterFogColor *= clampEyeBrightness;
         waterFogColor *= 1.0 - blindFactor;

    #ifdef OVERWORLD
    vec3 waterFogTint = lightCol;
    #endif

    #ifdef NETHER
    vec3 waterFogTint = netherCol.rgb;
    #endif

    #ifdef END
    vec3 waterFogTint = endCol.rgb;
    #endif

    waterFogTint = sqrt(waterFogTint * length(waterFogTint));

    return vec4(waterFogColor * waterFogTint, fog);
}