#ifdef OVERWORLD
float ug = mix(clamp((cameraPosition.y - 32.0) / 16.0, 0.0, 1.0), 1.0, eBS);
#endif

vec3 getAtmosphere(vec3 viewPos) {
    vec3 nViewPos = normalize(viewPos);

    float VoS = dot(nViewPos, sunVec);
    float VoU = dot(nViewPos, upVec);
    float VoUClamped = clamp(VoU, 0.0, 1.0);
    float VoUClampedInv = clamp(VoU, -1.0, 0.0);

    float timeBrightnessFactor = 1.0 - pow4(timeBrightness);
    float sunMix = (VoS * 0.75 + 0.25) * pow2(1.0 - VoUClamped);
    float horizonMix = pow3(1.0 - VoUClamped) * 0.6 * timeBrightnessFactor;
    float lightMix = (1.0 - sunMix) * (1.0 - horizonMix);
    float skyDensity = exp(-(1.0 - (1.0 - VoUClamped)));
    float skyDensityInv = exp(-(1.0 - (1.0 + VoUClampedInv)));

    //Day & Night Sky
    vec3 daySky = vec3(SKY_R, SKY_G, SKY_B) / 255.0 * SKY_I * max(timeBrightness, 0.75);
    vec3 nightSky = lightNight;

    daySky = mix(lightSun, daySky, lightMix);

    vec3 sky = mix(nightSky, daySky, pow3(sunVisibility));
         sky *= sky;

    //Weather Sky
    vec3 weatherSky = weatherCol * weatherCol * 0.05 * (1.0 + sunVisibility * 6.0);
	sky = mix(sky, weatherSky, rainStrength);

    return sky * mix(pow(skyDensity, 1.5), 1.0, rainStrength) * skyDensityInv;
}