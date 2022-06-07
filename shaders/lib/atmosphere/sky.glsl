#ifdef OVERWORLD
float ug = mix(clamp((cameraPosition.y - 32.0) / 16.0, 0.0, 1.0), 1.0, eBS);
#endif

//Constant Colors For Fake Liught Scattering
const vec3 downScatteringColor = vec3(4.25, 0.25, 0.15) * 8.0 * SKY_I;
const vec3 upScatteringColor = vec3(1.0, 1.25, 0.15) * 8.0 * SKY_I;

vec3 getAtmosphere(vec3 viewPos) {
    vec3 nViewPos = normalize(viewPos);

    float VoS = dot(nViewPos, sunVec);
    float VoU = max(dot(nViewPos, upVec), 0.0);

    //Set Variables Here
    float exposure = exp2(timeBrightness * 0.75 - 0.75);
    float sunMix = 1.0 + VoS * 0.5;
    float horizonMix = 1.0 - VoU;
    float lightMix = (1.0 - pow2(sunMix) * pow4(horizonMix) * 0.5) * (1.0 - pow4(horizonMix) * 0.25);
    float skyDensity = exp(-(1.0 - pow(horizonMix, 0.75)) * 2.0);

    //Day & Night Sky
    vec3 daySky = vec3(SKY_R, SKY_G, SKY_B) / 255.0 * SKY_I * exposure;

    //Perbiome Sky
    #ifdef FOG_PERBIOME
    daySky = getBiomeColor(daySky);
    #endif

    daySky = mix(lightSun, daySky, lightMix);

    vec3 sky = mix(lightNight, daySky, pow3(sunVisibility));
         sky = pow(sky, vec3(1.5 + timeBrightness));

    //Fake Light Scattering
    float scatteringFactor = sunVisibility * pow2(VoU) * sunMix;
    sky *= 1.0 + scatteringFactor;
    sky = mix(sky, upScatteringColor, pow8(horizonMix) * scatteringFactor);
    sky = mix(sky, downScatteringColor, pow16(horizonMix) * scatteringFactor);

    //Weather Sky
    vec3 weatherSky = weatherCol * weatherCol * 0.05 * (1.0 + pow3(sunVisibility) * 9.0);
	sky = mix(sky, weatherSky, rainStrength);

    return sky * skyDensity;
}