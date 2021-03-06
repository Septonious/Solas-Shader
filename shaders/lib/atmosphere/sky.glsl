//Constant Colors For Fake Light Scattering
vec3 highScatteringColor = vec3(0.85, 1.00, 0.15) * 0.75;
vec3 midScatteringColor  = vec3(1.35, 0.40, 0.25);
vec3 downScatteringColor = vec3(1.45, 0.35, 0.20) * 1.25;

vec3 getAtmosphere(vec3 viewPos) {
    vec3 nViewPos = normalize(viewPos);

    float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
    float VoU = dot(nViewPos, upVec);

    #ifdef SKY_GROUND
    VoU = max(VoU, 0.001);
    #endif

    //Set Variables Here
    float absVoU = abs(VoU);
    float VoUFactor = absVoU - sqrt(absVoU);

    float sunFactor = sunVisibility * 0.5 + VoS * 0.5;
    float horizonFactor = pow16(1.0 - pow2(absVoU));

    float scatteringFactor = sunVisibility * pow2(1.0 - timeBrightness) * (1.0 - rainStrength) * sunFactor;
    float skyDensity = mix(exp(-(1.0 - (1.0 - absVoU))), 0.9 - sunVisibility * 0.3, rainStrength * 0.75);

    //Day & Night Sky
    vec3 daySky = mix(skyColSqrt, pow(skyColor, vec3(1.25)) * 1.25, dfade);
    vec3 sky = mix(lightNight, daySky, sunVisibility) * skyDensity;

    //Fake Light Scattering
    sky = mix(sky, downScatteringColor, horizonFactor * scatteringFactor * 0.75);
    sky = mix(sky, midScatteringColor, pow8(VoUFactor * 3.5) * scatteringFactor);
    sky = mix(sky, highScatteringColor, (1.0 - horizonFactor) * (1.0 - pow8(VoUFactor * 3.5)) * pow4(VoUFactor * 3.0) * scatteringFactor);

    //Weather Sky
	sky = mix(sky, lightColSqrt * skyDensity, sqrt(rainStrength));

    //Underground Sky
	sky = mix(minLightCol, sky, ug);

    return sky;
}