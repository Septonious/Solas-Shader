uniform sampler2DShadow shadowtex0;

#ifdef SHADOW_COLOR
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
#endif

const vec2 shadowOffsets[4] = vec2[4](
    vec2( 0.00,  0.75),
    vec2( 0.75,  0.00),
    vec2( 0.00, -0.75),
    vec2(-0.75,  0.00)
);

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
        vec2 shadowOffset = shadowOffsets[i] * shadowBlurStrength + dither;
        shadow0 += shadow2D(shadowtex0, vec3(shadowPos.st + shadowOffset, shadowPos.z)).x;
    }
    shadow0 /= float(shadowSamples);

    vec3 shadowCol = vec3(0.0);
    #ifdef SHADOW_COLOR
    if (shadow0 < 0.999) {
        for (int i = 0; i < shadowSamples; i++) {
            vec2 shadowOffset = shadowOffsets[i] * shadowBlurStrength + dither;
            shadowCol += texture2D(shadowcolor0, shadowPos.st + shadowOffset).rgb *
                         shadow2D(shadowtex1, vec3(shadowPos.st + shadowOffset, shadowPos.z)).x;
        }
        shadowCol /= float(shadowSamples);
    }
    #endif

    return clamp(shadowCol * (1.0 - shadow0) + shadow0, 0.0, 1.0);
}

vec3 getShadow(vec3 worldPos, float dither) {
    vec3 shadowPos = calculateShadowPos(worldPos);
    vec3 shadow = sampleFilteredShadow(shadowPos, shadowBlurStrength, dither);

    return shadow;
}