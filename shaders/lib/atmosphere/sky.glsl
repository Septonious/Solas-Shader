vec3 getAtmosphere(vec3 viewPos) {
     //Variables
     vec3 nViewPos = normalize(viewPos);

     float VoSRaw = dot(nViewPos, sunVec);
     float VoURaw = dot(nViewPos, upVec);
     float VoUClamped = clamp(VoURaw, 0.0, 1.0);
     float VoSClamped = clamp(VoSRaw, 0.0, 1.0);
     float morningEvening = (1.0 - timeBrightness) * sunVisibility * sunVisibility * 0.5;

     //Fake Light Scattering
     float skyDensity = exp(-0.75 * VoUClamped);
           skyDensity = mix(skyDensity, 1.0, wetness * 0.5);
     float belowHorizon = 1.0 + clamp(VoURaw, -1.0, -0.25);
     float scatteringColorMixer = (1.0 + VoURaw) * 0.35;
     float scatteringWidth = pow(1.0 - VoUClamped, 2.0 - VoSClamped);

     float scatteringMixer = sqrt(sunVisibility) * (1.0 - wetness * 0.5) * (1.0 - timeBrightness * timeBrightness * 0.5);
           scatteringMixer *= 0.15 + exp(VoSClamped) * 0.15;
           scatteringMixer = clamp(scatteringMixer * belowHorizon * scatteringWidth, 0.0, 1.0);

     vec3 scatteringColor = mix(vec3(1.5, 0.4, 0.2), vec3(0.4, 1.5, 0.2), scatteringColorMixer);
          scatteringColor = mix(scatteringColor, lightCol, 0.25 + timeBrightnessSqrt * 0.5) * (1.0 + morningEvening);

     //Day, Night and Rain Sky
     vec3 daySky = mix(skyColSqrt, pow(skyColor, vec3(1.4)) * 1.25, timeBrightness);
          daySky = mix(daySky, lightCol, pow8(1.0 - VoUClamped) * 0.2 * (1.0 - wetness));
     vec3 sky = mix(lightNight, daySky, sunVisibility);
          sky = mix(sky, weatherCol * clamp(sunVisibility, 0.35, 1.0), wetness * 0.75);
          sky = mix(sky, scatteringColor, scatteringMixer) * skyDensity;

     //Underground Sky
     sky = mix(minLightCol, sky, caveFactor);

     return sky;
}