vec3 getAtmosphere(vec3 viewPos) {
    //Variables
    vec3 nViewPos = normalize(viewPos);

    float VoSRaw = dot(nViewPos, sunVec);
    float VoURaw = dot(nViewPos, upVec);
    float VoUClamped = clamp(VoURaw, 0.0, 1.0);
    float VoSClamped = clamp(VoSRaw, 0.0, 1.0);
    float invVoS = 1.0 + clamp(VoSRaw, -1.0, 0.0);

    //Fake Light Scattering
    float skyDensity = mix(exp(-0.8 * VoUClamped), 1.0, rainStrength * 0.5);
    float belowHorizon = 1.0 + clamp(VoURaw, -1.0, -0.25);
    float scatteringColorMixer = clamp((1.0 + VoURaw) * 0.5, 0.25, 1.0 - sunVisibility * sunVisibility * 0.75);
    float scatteringWidth = pow(1.0 - VoUClamped, (3.0 + sunVisibility) - VoSClamped * 2.0);

    float scatteringMixer = pow(sunVisibility, 0.75) * mix(0.5 + invVoS * 0.5, 1, sunVisibility * sunVisibility) * scatteringWidth * belowHorizon * (1.0 - sunVisibility * sunVisibility * 0.25) * (1.0 - timeBrightness * 0.5) * (1.0 - rainStrength);
    vec3 scatteringColor = mix(mix(vec3(1.2, 0.2, 0.1), lightCol, sunVisibility * sunVisibility * 0.5 + timeBrightness * 0.5), vec3(0.5, 0.8, 0.2), scatteringColorMixer);

    //Day, Night and Rain Sky
    vec3 daySky = mix(skyColSqrt, pow(skyColor, vec3(1.25)) * 1.25, timeBrightness);
    vec3 sky = mix(mix(lightNight, daySky, sunVisibility), weatherCol * clamp(sunVisibility, 0.25, 0.75), rainStrength) * skyDensity;
         sky = mix(sky, scatteringColor, scatteringMixer);

    //Underground Sky
	sky = mix(caveMinLightCol, sky, caveFactor);

    return sky;
}