#ifdef OVERWORLD
float ug = mix(clamp((cameraPosition.y - 32.0) / 16.0, 0.0, 1.0), 1.0, eBS);
#endif

//Constant Colors For Fake Light Scattering
const vec3 downScatteringColor = vec3(4.8, 0.6, 0.4);
const vec3 upScatteringColor = vec3(1.1, 1.3, 0.5);

vec3 getAtmosphere(vec3 viewPos) {
    vec3 nViewPos = normalize(viewPos);

    float VoS = dot(nViewPos, sunVec);
    float VoU = dot(nViewPos, upVec);

    #ifdef SKY_GROUND
    VoU = max(VoU, 0.001);
    #endif

    //Set Variables Here
    float exposure = exp2(timeBrightness - 0.5);
    float sunMix = 0.6 + VoS * 0.4;
    float horizonMix = 1.0 - pow(abs(VoU), 1.0 + sunVisibility);
    float lightMix = sunMix * (1.0 - pow6(horizonMix) * 0.6);
    float skyDensity = exp(-(1.0 - (1.0 - VoU)) * (1.0 + timeBrightness));

    //Day & Night Sky
    vec3 daySky = vec3(SKY_R, SKY_G, SKY_B) / 255.0 * SKY_I * exposure;

    //Perbiome Sky
    #ifdef FOG_PERBIOME
    daySky = getBiomeColor(daySky);
    #endif

    vec3 sky = mix(lightNight, daySky, pow2(sunVisibility));
         sky *= sky;

    //Fake Light Scattering
    float scatteringFactor = sunVisibility * lightMix * (1.0 - timeBrightness);
    sky = mix(sky, upScatteringColor * (0.25 + sunVisibility), pow5(horizonMix) * scatteringFactor);
    sky = mix(sky, downScatteringColor * (0.5 + sunVisibility), pow20(horizonMix) * scatteringFactor * 0.25);

    //Weather Sky
    vec3 weatherSky = pow2(weatherCol) * 0.05 * (1.0 + pow6(sunVisibility) * 7.0);
	sky = mix(sky, weatherSky, rainStrength);

    return sky * mix(skyDensity, 1.0, pow3(rainStrength));
}