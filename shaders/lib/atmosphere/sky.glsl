#ifdef OVERWORLD
float ug = mix(clamp((cameraPosition.y - 32.0) / 16.0, 0.0, 1.0), 1.0, eBS);
#endif

const vec3 downScatteringColor = vec3(3.0, 0.15, 0.05) * 4.0;
const vec3 upScatteringColor = vec3(1.0, 1.5, 0.15) * 4.0;

vec3 getAtmosphere(vec3 viewPos) {
    vec3 nViewPos = normalize(viewPos);

    float VoS = dot(nViewPos, sunVec);
    float VoU = dot(nViewPos, upVec);

    float timeBrightnessFactor = 1.0 - timeBrightness;
    float sunMix = pow3(0.5 * VoS + 0.5) * timeBrightnessFactor;
    float horizonMix = pow3(1.0 - abs(VoU)) * 0.75;
    float lightMix = (1.0 - sunMix) * (1.0 - horizonMix);
    float skyDensity = exp(-(1.0 - (1.0 - abs(VoU))));

    //Day & Night Sky
    vec3 daySky = vec3(SKY_R, SKY_G, SKY_B) / 255.0 * SKY_I * max(timeBrightness, 0.75);

    #ifdef FOG_PERBIOME
    daySky = getBiomeColor(daySky);
    #endif

    daySky = mix(lightSun, daySky, lightMix);

    vec3 sky = mix(lightNight, daySky, pow2(sunVisibility));
         sky *= sky;

    //Fake Light Scattering
    VoU = max(VoU, 0.0);
    float scatteringFactor = (1.0 - pow16(timeAngle) + pow16(timeAngle)) * sunVisibility * VoU * moonVisibility;
    sky *= 1.0 + scatteringFactor;
    scatteringFactor *= 0.75 + VoS * 0.75;
    sky = mix(sky, upScatteringColor, pow12(1.0 - VoU) * scatteringFactor);
    sky = mix(sky, downScatteringColor, pow24(1.0 - VoU) * scatteringFactor);

    //Weather Sky
    vec3 weatherSky = weatherCol * weatherCol * 0.05 * (1.0 + sunVisibility * 6.0);
	sky = mix(sky, weatherSky, rainStrength);

    return sky * mix(skyDensity, 1.0, rainStrength);
}