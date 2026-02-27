vec3 getAtmosphere(vec3 viewPos, vec3 worldPos, out float atmosphereHardMixFactor) {
    vec3 daySkyColor = normalize(skyColor + 0.000001) * fmix(vec3(1.0), biomeColor, isSpecificBiome);
             daySkyColor.r *= 1.25 - timeBrightnessSqrt * 0.25;
    vec3 atmosphere = fmix(daySkyColor, lightNight * 0.5, moonVisibility);
    float altitudeFactor = min(max(cameraPosition.y, 0.0) / KARMAN_LINE, 1.0);
    float altitudeFactor10k = min(max(cameraPosition.y, 0.0) * 0.0001, 1.0);

    vec3 nWorldPos = normalize(worldPos);
    vec3 nViewPos = normalize(viewPos);

    float heightPositive = max(nWorldPos.y * (1.0 - altitudeFactor * 0.5) + altitudeFactor * 0.5, 0.0);
    float density = clamp((1.0 - heightPositive * (0.65 + altitudeFactor * altitudeFactor * 3.0)) * (1.0 + pow4(altitudeFactor) * 9.0), 0.0, 1.0);

    atmosphereHardMixFactor = altitudeFactor * density;
    atmosphere *= density;

    float VoS = dot(nViewPos, sunVec);
    float VoSPositive = VoS * 0.5 + 0.5;
    float VoSClamped = clamp(VoS, 0.0, 1.0);

    float heightClamped = clamp(nWorldPos.y + altitudeFactor * 0.55, 0.0, 1.0);
    float colorMixer = pow(heightClamped + 0.15, 0.4 + timeBrightnessSqrt * 0.15);
    vec3 scatteringColor = fmix(vec3(8.8 - timeBrightnessSqrt * 5.0, 1.2 + timeBrightnessSqrt * 3.0, 0.0) * (1.0 + timeBrightnessSqrt), vec3(4.0, 5.8 - sunVisibility, 0.2), colorMixer);
         scatteringColor = fmix(scatteringColor, lightColSqrt * 4.0, heightPositive * heightPositive * 0.5 + timeBrightness * 0.5);
         scatteringColor *= 2.0 * (heightClamped + 0.15 + VoSClamped * VoSClamped * 0.15) * clamp(pow(1.0 - (heightClamped + 0.15), 3.0 - VoSClamped), 0.0, 1.0);
         scatteringColor *= 1.0 - timeBrightnessSqrt * 0.5;
         scatteringColor = mix(scatteringColor, lightColSqrt, timeBrightnessSqrt * 0.75);
    float scattering = pow2(1.0 - (heightClamped + 0.15)) * (0.75 + heightPositive * 0.75) * (1.0 - VoSClamped * VoSClamped * 0.25) * pow(length(scatteringColor), 0.33) * sunVisibility * mix(1.0, atmosphereHardMixFactor * 0.75, altitudeFactor);

    atmosphere = fmix(atmosphere, scatteringColor * 0.75, scattering * SUNRISE_SUNSET_INTENSITY);
    atmosphere *= 1.0 - wetness * 0.25 * (1.0 - altitudeFactor10k);

    //Fade atmosphere to dark gray underground
    atmosphere = fmix(caveMinLightCol * (1.0 - isCaveBiome) + caveBiomeColor, atmosphere, caveFactor);

    return atmosphere;
}