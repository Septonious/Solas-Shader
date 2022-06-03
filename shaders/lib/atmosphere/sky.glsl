#ifdef OVERWORLD
float ug = mix(clamp((cameraPosition.y - 32.0) / 16.0, 0.0, 1.0), 1.0, eBS);
#endif

vec3 getAtmosphere(vec3 viewPos) {
    vec3 nViewPos = normalize(viewPos);

    float VoS = dot(nViewPos, sunVec);
    float VoU = dot(nViewPos, upVec);
    float VoUClamped = clamp(VoU, 0.0, 1.0);

    float timeBrightnessFactor = 1.0 - timeBrightness;
    float sunMix = pow4(0.5 * VoS + 0.5) * timeBrightnessFactor * 0.5;
    float horizonMix = pow(1.0 - VoUClamped, 1.5);
    float lightMix = (1.0 - sunMix) * (1.0 - horizonMix);
    float skyDensity = exp(-(1.0 - (1.0 - VoUClamped)));

    //Day & Night Sky
    vec3 daySky = vec3(SKY_R, SKY_G, SKY_B) / 255.0 * SKY_I;

    daySky = mix(lightSun, daySky, lightMix);

    vec3 sky = mix(lightNight, daySky, pow2(sunVisibility));
         sky *= sky;

    //Weather Sky
    vec3 weatherSky = weatherCol * weatherCol * 0.05 * (1.0 + sunVisibility * 6.0);
	sky = mix(sky, weatherSky, rainStrength);

    return sky * mix(pow(abs(skyDensity), 1.5), 1.0, rainStrength);
}