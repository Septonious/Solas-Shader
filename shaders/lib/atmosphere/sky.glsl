vec3 getAtmosphere(vec3 viewPos) {
    //Variables
    vec3 nViewPos = normalize(viewPos);
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
    
    float VoSRaw = dot(nViewPos, sunVec);
    float VoURaw = dot(nViewPos, upVec);
    float VoUClamped = clamp(VoURaw, 0.0, 1.0);
    float VoSClamped = clamp(VoSRaw, 0.0, 1.0);
    float invVoS = 1.0 + clamp(VoSRaw, -1.0, 0.0);

    //Fake Light Scattering
    float skyDensity = mix(exp(-0.8 * VoUClamped), 1.0, wetness * 0.5);
    float belowHorizon = 1.0 + clamp(VoURaw, -1.0, -0.25);
    float scatteringColorMixer = (1.0 + VoURaw) * 0.45;
    float scatteringWidth = pow(sqrt(1.0 - VoUClamped), 3.0 - VoSClamped * 2.0 + sunVisibility);
    float glare = pow8(clamp(dot(nViewPos, lightVec), 0.0, 1.0));

    float scatteringMixer = sqrt(sunVisibility) * (0.4 + invVoS * 0.3) * scatteringWidth * belowHorizon * (1.0 - wetness) * (1.0 - timeBrightness * 0.25);
    vec3 scatteringColor = mix(mix(vec3(1.2, 0.2, 0.1), vec3(0.5, 0.9, 0.2), scatteringColorMixer), lightColSqrt, sunVisibility * sunVisibility);

    //Day, Night and Rain Sky
    vec3 daySky = mix(skyColSqrt, pow(skyColor, vec3(1.25)) * 1.25, timeBrightness);
         daySky *= 1.0 + glare * VoUClamped;
    vec3 sky = mix(mix(lightNight * 0.75, daySky, sunVisibility), weatherCol * clamp(sunVisibility, 0.25, 0.85), wetness) * skyDensity;
         sky = mix(sky, scatteringColor, scatteringMixer);

    //Underground Sky
	sky = mix(caveMinLightCol, sky, caveFactor);

    return sky;
}