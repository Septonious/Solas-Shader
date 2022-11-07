vec3 getAtmosphere(vec3 viewPos) {
    //Variables
    vec3 nViewPos = normalize(viewPos);

    float VoSRaw = dot(nViewPos, sunVec);
    float VoURaw = dot(nViewPos, upVec);
    float VouClamped = clamp(VoURaw, 0.0, 1.0);
    float VoSClamped = clamp(VoSRaw, 0.0, 1.0);
    float invVoS = 1.0 + clamp(VoSRaw, -1.0, 0.0);
    float horizonFactor = 1.0 - abs(VoURaw);

	float sun = clamp(VoSClamped * 0.5 + 0.5, 0.0, 1.0);
		  sun = (0.01 / (1.0 - 0.99 * sun) - 0.01);

    //Fake Light Scattering
    float skyDensity = exp(-0.75 * VouClamped);
    float baseScatteringMixer = mix(0.15, 0.20, invVoS) * sunVisibility * pow3(horizonFactor);
    float sunScatteringMixer = mix(0.10, 0.25, invVoS) * pow2(horizonFactor) + sun * 0.15;
    float totalScatteringMixer = mix(baseScatteringMixer, sunScatteringMixer, sunVisibility * sunVisibility) * (1.0 - timeBrightness * 0.75) * (1.0 - rainStrength);

    //Day, Night and Rain Sky
    vec3 daySky = mix(skyColSqrt, pow(skyColor, vec3(1.25)) * 1.5, timeBrightnessSqrt);
    vec3 sky = mix(mix(lightNight, daySky, sunVisibility), weatherCol * clamp(sunVisibility, 0.25, 0.75), rainStrength) * skyDensity;

    vec3 scattering = mix(lowScatteringColor, highScatteringColor, sqrt(VouClamped) * (1.0 - timeBrightnessSqrt * 0.5));
    sky = mix(sky, scattering, totalScatteringMixer);

    //Underground Sky
	sky = mix(caveMinLightCol, sky, caveFactor);

    return sky;
}