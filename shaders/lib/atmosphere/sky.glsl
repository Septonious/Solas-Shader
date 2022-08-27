//Constant Colors For Fake Light Scattering
//vec3 highScatteringColor = vec3(0.85, 1.00, 0.15);
//vec3 midScatteringColor  = vec3(1.35, 0.40, 0.25);
//vec3 downScatteringColor = vec3(1.55, 0.60, 0.05);

vec3 getAtmosphere(vec3 viewPos) {
    vec3 nViewPos = normalize(viewPos);

    float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
          VoS = mix(pow2(VoS), 0.35 + VoS * 0.65, sunVisibility * sunVisibility);
    float VoU = dot(nViewPos, upVec);

    #ifdef SKY_GROUND
    VoU = max(VoU, 0.001);
    #endif

    //Set Variables Here
    float absVoU = abs(VoU);
    float VoUFactor = absVoU - sqrt(absVoU);
    float horizonFactor = pow16(1.0 - absVoU * absVoU);

    float scatteringFactor = clamp(sunVisibility * (1.0 - rainStrength) * VoS, 0.0, (1.0 - dfade) * 0.75 * sunVisibility * VoS);
    float skyDensity = exp(-absVoU);
          skyDensity = mix(skyDensity, 0.35, 0.5 - sunVisibility * 0.5);
          skyDensity = mix(skyDensity, 0.7, rainStrength * rainStrength * 0.8);

    //Day & Night Sky
    vec3 daySky = mix(skyColSqrt, pow(skyColor, vec3(1.25)) * 1.5, dfade);
    vec3 sky = mix(lightNight, daySky, sunVisibility) * skyDensity;

    //Fake Light Scattering
    sky = mix(sky, mix(lowScatteringColor, lightCol, sqrtdfade), horizonFactor * scatteringFactor);
    sky = mix(sky, mix(midScatteringColor, lightCol, sqrtdfade), pow6(VoUFactor * 3.5) * scatteringFactor * 0.75);
    sky = mix(sky, highScatteringColor, (1.0 - horizonFactor) * (1.0 - pow6(VoUFactor * 3.5)) * pow6(VoUFactor * 3.5) * scatteringFactor * 0.75);

    //Weather Sky
	sky = mix(sky, lightColSqrt * skyDensity, rainStrength);

    //Underground Sky
	sky = mix(minLightCol, sky, ug);

    return sky;
}