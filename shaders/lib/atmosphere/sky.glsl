vec3 getAtmosphere(vec3 viewPos) {
    vec3 nViewPos = normalize(viewPos);

    float VoS = dot(nViewPos, sunVec);
    float VoM = dot(nViewPos, -sunVec);
    float VoL = VoS * sunVisibility + VoM * moonVisibility;
    float VoU = dot(nViewPos, upVec);
    float VoSPositive = VoS * 0.5 + 0.5;
    float VoUPositive = VoU * 0.5 + 0.5;
    float VoSClamped = clamp(VoS, 0.0, 1.0);
    float VoUClamped = clamp(VoU, 0.0, 1.0);

    float skyDensity = exp(-(1.0 - pow(1.0 - max(VoU, 0.0), 1.5 - VoL * 0.75)) / 1.50);

    //Fake light scattering
    float mieScattering = pow16(VoSClamped);

    float VoUcm = max(VoUClamped + 0.15, 0.0);
    float colorMixer = pow(VoUcm, 0.4 + timeBrightnessSqrt * 0.15);
    vec3 scattering1 = mix(vec3(8.8 - timeBrightnessSqrt * 4.8, 1.2, 0.0), vec3(4.0, 5.8 - sunVisibility, 0.2), colorMixer);
         scattering1 = mix(scattering1, lightColSqrt * 4.0, VoUPositive * VoUPositive * 0.5 + timeBrightness * 0.5);
         scattering1 *= VoUcm * clamp(pow(1.0 - VoUcm, 3.0 - VoSClamped), 0.0, 1.0);
         scattering1 = pow(scattering1, vec3(1.0 + VoSPositive * 0.4)) * (1.0 + VoSPositive * (1.0 - timeBrightnessSqrt) * 0.5);
         scattering1 *= 1.0 - timeBrightnessSqrt * 0.75;

    float scatteringMixer = pow2(1.0 - VoUcm) * (0.6 + VoUPositive * 0.6);
    float scattering1Mixer = scatteringMixer * pow(length(scattering1), 0.33) * (1.0 - wetness * 0.75);
    float scattering2Mixer = 0.15 * pow2(1.0 - abs(VoU)) * timeBrightness + sunVisibility * VoSPositive * pow3(scatteringMixer) * 0.35;

    vec3 nSkyColor = normalize(skyColor + 0.000001) * mix(vec3(1.0), biomeColor, isSpecificBiome);
    vec3 daySky = mix(nSkyColor, vec3(0.67, 0.48, 0.85), 0.7 - sunVisibility * 0.4 - timeBrightnessSqrt * 0.3);
         daySky = mix(daySky, scattering1 * (1.0 + timeBrightnessSqrt + timeBrightness), scattering1Mixer);
         daySky = mix(daySky, pow(lightColSqrt, vec3(1.5 - timeBrightnessSqrt * 0.5)) * (2.0 + mieScattering), scattering2Mixer);

    vec3 nightSky = mix(lightNight * 0.65, vec3(0.04, 0.11, 0.25), VoUClamped * 0.25);
    vec3 atmosphere = mix(nightSky, daySky, sunVisibility);
         atmosphere *= 1.0 - wetness * 0.125;
         atmosphere *= skyDensity;

    //Fade atmosphere to dark gray underground
    atmosphere = mix(caveMinLightCol * (1.0 - isCaveBiome) + caveBiomeColor, atmosphere, caveFactor);

    return atmosphere;
}