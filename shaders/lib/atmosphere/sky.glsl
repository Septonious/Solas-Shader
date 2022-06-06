#ifdef OVERWORLD
float ug = mix(clamp((cameraPosition.y - 32.0) / 16.0, 0.0, 1.0), 1.0, eBS);
#endif

//Constant Colors For Fake Liught Scattering
const vec3 downScatteringColor = vec3(3.15, 0.15, 0.05) * 4.0 * SKY_I;
const vec3 upScatteringColor = vec3(1.0, 1.35, 0.15) * 4.0 * SKY_I;

vec3 getAtmosphere(vec3 viewPos) {
    vec3 nViewPos = normalize(viewPos);

    float VoS = dot(nViewPos, sunVec);
    float VoU = dot(nViewPos, upVec);

    //Set Variables Here
    float exposure = exp2(timeBrightness * 0.75 - 0.75);
    float sunMix = 1.00 + VoS * 0.5;
    float horizonMix = 1.0 - abs(VoU);
    float lightMix = (1.0 - pow2(sunMix) * (0.5 - timeBrightness * 0.25) * horizonMix) * (1.0 - pow2(horizonMix) * 0.5);
    float skyDensity = pow2(exp(-(1.0 - horizonMix)));

    //Day & Night Sky
    vec3 daySky = vec3(SKY_R, SKY_G, SKY_B) / 255.0 * SKY_I * exposure;

    //Perbiome Sky
    #ifdef FOG_PERBIOME
    daySky = getBiomeColor(daySky);
    #endif

    daySky = mix(lightSun * (1.0 + timeBrightness * 0.25), daySky, lightMix);

    vec3 sky = mix(lightNight, daySky, pow3(sunVisibility));
         sky = pow(sky, vec3(2.0 + timeBrightness));

    //Fake Light Scattering
    VoU = max(VoU, 0.0);
    float scatteringFactor = clamp(1.0 - pow16(timeAngle) + pow16(timeAngle), 0.0, 1.0) * sunVisibility * pow2(abs(VoU)) * sunMix;
    sky *= 1.0 + scatteringFactor;
    sky = mix(sky, upScatteringColor, pow8(horizonMix) * scatteringFactor);
    sky = mix(sky, downScatteringColor, pow16(horizonMix) * scatteringFactor);

    //Weather Sky
    vec3 weatherSky = weatherCol * weatherCol * 0.05 * (1.0 + pow3(sunVisibility) * 9.0);
	sky = mix(sky, weatherSky, rainStrength);

    return sky * mix(skyDensity, 1.0, rainStrength);
}