const float multiScatterPhase = 0.5;

float getZenithDensity(float density, float x) {
    return density / pow(max(x, 0.35e-2), 0.75);
}

vec3 getSkyAbsorption(vec3 x, float y){
    return exp2(-x * y) * 2.0;;
}

vec3 jodieReinhardTonemap(vec3 c){
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    vec3 tc = c / (c + 1.0);

    return mix(c / (l + 1.0), tc, tc);
}

vec3 getAtmosphericScattering(vec3 viewPos, vec3 lightPos) {
    //Variables
    vec3 nViewPos = normalize(viewPos);

    float VoSRaw = dot(nViewPos, sunVec);
    float VoURaw = dot(nViewPos, upVec);
    float VoUClamped = clamp(VoURaw, 0.0, 1.0);
    float VoSClamped = clamp(VoSRaw, 0.0, 1.0);
          VoSClamped = pow(VoSClamped, 1.25);

    //Prepare scattering properties
    float skyDensity = exp(-0.75 * pow(VoUClamped, 1.5 - timeBrightness * 0.75));
    float scatteringWidth = pow(1.0 - VoUClamped, 2.0 - VoSClamped) * pow3(min(1.0 + VoURaw, 1.0));

    float sunScatteringMixer = (1.0 - timeBrightness * 0.5) * (1.0 - wetness * 0.45) * VoSClamped;
          sunScatteringMixer = sunScatteringMixer * scatteringWidth * 0.6;

    float rayleighScatteringMixer = 0.3 + sunVisibility * 0.3;
          rayleighScatteringMixer *= (1.0 - wetness * 0.45) * (1.0 - timeBrightness * timeBrightness * 0.5);

    //Realistic sky scattering
    vec3 worldPos = normalize(ToWorld(viewPos)) * PI;

    float density = 1.25 - timeBrightness * 0.5;
    float zenith = getZenithDensity(density, worldPos.y);
    float sunPointDistMult = clamp(length(max(lightPos.y + multiScatterPhase, 0.0)), 0.0, 1.0);
    
    const vec3 newSkyCol = vec3(0.39, 0.57, 1.0) * 2.5;
    vec3 absorption = getSkyAbsorption(newSkyCol, zenith);
    vec3 sunAbsorption = getSkyAbsorption(newSkyCol, getZenithDensity(density, lightPos.y + multiScatterPhase));
    vec3 sky = newSkyCol * zenith;
    
    vec3 totalSky = mix(sky * absorption, sky / sqrt(sky * sky + 2.0), sunPointDistMult);
         totalSky *= sunAbsorption * 0.5 + 0.5 * length(sunAbsorption);

    //Final calculations
    vec3 daySky = mix(normalize(skyColor + 0.00001), vec3(0.62, 0.69, 1.00), 0.5 - timeBrightness * 0.25);
         daySky = mix(daySky * skyDensity, totalSky, rayleighScatteringMixer);
         daySky = jodieReinhardTonemap(daySky * PI);
         daySky = pow(daySky, vec3(2.2));
         daySky = mix(daySky, lightColSqrt, pow2(1.0 - VoUClamped) * (1.0 - wetness * 0.5) * (1.0 - timeBrightness) * 0.4);
         daySky = mix(daySky, lightColSqrt, sunScatteringMixer);
    vec3 nightSky = lightNight * 0.6;
         //Tint the atmosphere with slight green when aurora is visible
         #ifdef AURORA
         float visibilityMultiplier = pow8(1.0 - sunVisibility) * (1.0 - wetness) * AURORA_BRIGHTNESS;
         float auroraVisibility = 0.0;

         #ifdef AURORA_FULL_MOON_VISIBILITY
         auroraVisibility = mix(auroraVisibility, 1.0, float(moonPhase == 0));
         #endif

         #ifdef AURORA_COLD_BIOME_VISIBILITY
         auroraVisibility = mix(auroraVisibility, 1.0, isSnowy);
         #endif

         #ifdef AURORA_ALWAYS_VISIBLE
         auroraVisibility = 1.0;
         #endif

         auroraVisibility *= visibilityMultiplier;
         nightSky = mix(nightSky, vec3(0.4, 2.5, 0.9), 0.02 * auroraVisibility);
         #endif

         nightSky *= skyDensity;
    vec3 atmosphere = mix(nightSky, daySky, sunVisibility);
         atmosphere = mix(atmosphere, weatherCol * clamp(sunVisibility, 0.35, 1.0), wetness * 0.5);

    //Fade atmosphere to dark gray
    atmosphere = mix(caveMinLightCol, atmosphere, caveFactor);

    #if MC_VERSION >= 11900
    atmosphere *= 1.0 - darknessFactor;
    #endif

    atmosphere *= 1.0 - blindFactor;

    return atmosphere;
}