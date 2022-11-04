//Constant Colors For Fake Light Scattering
//vec3 highScatteringColor = vec3(0.85, 1.00, 0.15);
//vec3 midScatteringColor  = vec3(1.35, 0.40, 0.25);
//vec3 lowScatteringColor = vec3(1.55, 0.60, 0.05);

vec3 getAtmosphere(vec3 viewPos) {
    vec3 nViewPos = normalize(viewPos);

    float VoS = dot(nViewPos, sunVec);
          VoS = 1.0 + clamp(VoS, -1.0, 0.0);
          VoS = mix(VoS * 0.25, 0.1 + VoS * 0.1, sunVisibility);
    float VoU = dot(nViewPos, upVec);

    //Set Variables Here
    float horizonFactor = pow2(1.0 + clamp(VoU, -1.0, 0.0));
    VoU = clamp(VoU, 0.0, 1.0);

    float nVoU = pow(VoU, 1.75);
    float scatteringMixer = clamp(pow(exp(-24.0 * nVoU), 0.25), 0.0, 1.0);
    float scatteringFactor = clamp(sunVisibility * (1.0 - rainStrength) * VoS, 0.0, sunVisibility * (1.0 - timeBrightness * timeBrightness * 0.8) * VoS);

    float skyDensity = exp(-mix(1.0, 0.65, sunVisibility * (1.0 - timeBrightness)) * VoU);
          skyDensity = mix(skyDensity, 0.6, 0.5 - sunVisibility * 0.25);
          skyDensity = clamp(mix(skyDensity, 0.6, rainStrength * rainStrength * 0.7), 0.0, 1.0);

    //Day & Night Sky
    vec3 daySky = mix(skyColSqrt, pow(skyColor, vec3(1.25)) * 1.5, timeBrightness);
    vec3 sky = mix(lightNight, daySky, sunVisibility) * skyDensity;

    //Fake Light Scattering
    vec3 scattering = mix(mix(lowScatteringColor, highScatteringColor, horizonFactor * (1.0 - scatteringMixer * 0.75) * (1.0 - timeBrightnessSqrt)), lightColSqrt * 8.0, timeBrightnessSqrt);

    sky = mix(sky, scattering, clamp(pow(exp(-(20.0 + sunVisibility * sunVisibility * 20.0) * nVoU), 0.3), 0.0, 1.0) * scatteringFactor);

    //Weather Sky
	sky = mix(sky, lightColSqrt * skyDensity, rainStrength);

    //Underground Sky
	sky = mix(caveMinLightCol, sky, caveFactor);

    return sky;
}