#ifdef OVERWORLD
float ug = mix(clamp((cameraPosition.y - 32.0) / 16.0, 0.0, 1.0), 1.0, eBS);
#endif

const vec3 downScatteringColor = vec3(3.15, 0.15, 0.05) * 10.0 * SKY_I;
const vec3 upScatteringColor = vec3(1.0, 1.35, 0.15) * 10.0 * SKY_I;

vec3 getAtmosphere(vec3 viewPos) {
    vec3 nViewPos = normalize(viewPos);

    float VoS = dot(nViewPos, sunVec);
    float VoU = dot(nViewPos, upVec);

    float timeBrightnessFactor = 1.0 - timeBrightness;
    float sunMix = pow3(0.5 * VoS + 0.5) * timeBrightnessFactor * 0.5;
    float horizonMix = pow3(1.0 - abs(VoU)) * 0.5;
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
    float scatteringFactor = (1.0 - pow16(timeAngle) + pow16(timeAngle)) * sunVisibility * pow(VoU, 1.75) * moonVisibility * (1.0 + VoS * 0.5);
    sky *= 1.0 + scatteringFactor;
    sky = mix(sky, upScatteringColor, pow8(1.0 - VoU) * scatteringFactor);
    sky = mix(sky, downScatteringColor, pow16(1.0 - VoU) * scatteringFactor);

    //Weather Sky
    vec3 weatherSky = weatherCol * weatherCol * 0.05 * (1.0 + pow3(sunVisibility) * 9.0);
	sky = mix(sky, weatherSky, rainStrength);

    return sky * mix(skyDensity, 1.0, rainStrength);
}