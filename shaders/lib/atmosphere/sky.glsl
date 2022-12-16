vec3 getAtmosphere(vec3 viewPos) {
    //Variables
    vec3 nViewPos = normalize(viewPos);

    float VoSRaw = dot(nViewPos, sunVec);
    float VoURaw = dot(nViewPos, upVec);
    float VouClamped = clamp(VoURaw, 0.0, 1.0);
    float VoSClamped = clamp(VoSRaw, 0.0, 1.0);
    float invVoS = 1.0 + clamp(VoSRaw, -1.0, 0.0);
    float horizonFactor = 1.0 - abs(VoURaw);

    //Fake Light Scattering
    float skyDensity = exp(-0.75 * VouClamped);
    float baseScatteringMixer = mix(0.10, 0.20, invVoS) * sunVisibility * pow3(horizonFactor);
    float sunScatteringMixer = mix(0.10 * horizonFactor, 0.25, invVoS) * pow2(horizonFactor);
    float totalScatteringMixer = mix(baseScatteringMixer, sunScatteringMixer, sunVisibility * sunVisibility - timeBrightness * timeBrightness) * (1.0 - rainStrength) * horizonFactor;

    //Day, Night and Rain Sky
    vec3 daySky = mix(skyColSqrt, pow(skyColor, vec3(1.25)) * 1.25, timeBrightness);
    vec3 sky = mix(mix(lightNight, daySky, sunVisibility), weatherCol * clamp(sunVisibility, 0.25, 0.75), rainStrength) * skyDensity;

    vec3 scattering = mix(mix(lowScatteringColor, highScatteringColor, sqrt(VouClamped) * (1.0 - timeBrightnessSqrt)), lightCol, sunVisibility * sunVisibility * 0.75);
    sky = mix(sky, scattering, totalScatteringMixer);

    //Underground Sky
	sky = mix(caveMinLightCol, sky, caveFactor);

    return sky;
}