uniform sampler2DShadow shadowtex0;

#ifdef SHADOW_COLOR
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
#endif

vec2 offsetDist(float x) {
	float n = fract(x * 8.0) * PI;

    return vec2(cos(n), sin(n)) * x;
}

vec3 calculateShadowPos(vec3 worldPos) {
    vec3 shadowPos = ToShadow(worldPos);
    float distb = sqrt(shadowPos.x * shadowPos.x + shadowPos.y * shadowPos.y);
    float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);

    shadowPos.xy /= distortFactor;
    shadowPos.z *= 0.2;
    
    return shadowPos * 0.5 + 0.5;
}

vec3 sampleFilteredShadow(vec3 shadowPos, float shadowBlurStrength, float dither) {
    float shadow0 = 0.0;

    #ifdef GBUFFERS_TERRAIN
    int shadowSamples = SHADOW_SAMPLE_COUNT;
    #else
    int shadowSamples = 1;
    #endif

    for (int i = 0; i < shadowSamples; i++) {
        vec2 shadowOffset = offsetDist(float(i + dither)) * shadowBlurStrength;
        shadow0 += shadow2D(shadowtex0, vec3(shadowPos.st + shadowOffset, shadowPos.z)).x;
    }
    shadow0 /= shadowSamples;

    vec3 shadowCol = vec3(0.0);
    #ifdef SHADOW_COLOR
    if (shadow0 < 0.999) {
        for (int i = 0; i < shadowSamples; i++) {
            vec2 shadowOffset = offsetDist(float(i + dither)) * shadowBlurStrength;
            shadowCol += texture2D(shadowcolor0, shadowPos.st + shadowOffset).rgb *
                         shadow2D(shadowtex1, vec3(shadowPos.st + shadowOffset, shadowPos.z)).x;
        }
        shadowCol /= shadowSamples;
    }
    #endif

    return clamp(shadowCol * (1.0 - shadow0) + shadow0, 0.0, 1.0);
}