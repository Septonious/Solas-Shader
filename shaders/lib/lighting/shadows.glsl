uniform sampler2DShadow shadowtex0;

#ifdef SHADOW_COLOR
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
#endif

vec2 shadowOffsets[9] = vec2[9](
    vec2( 0.0, 0.0),
    vec2( 0.0, 1.0),
    vec2( 0.7, 0.7),
    vec2( 1.0, 0.0),
    vec2( 0.7,-0.7),
    vec2( 0.0,-1.0),
    vec2(-0.7,-0.7),
    vec2(-1.0, 0.0),
    vec2(-0.7, 0.7)
);

vec3 calculateShadowPos(vec3 worldPos) {
    vec3 shadowPos = ToShadow(worldPos);
    float distb = sqrt(shadowPos.x * shadowPos.x + shadowPos.y * shadowPos.y);
    float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);

    shadowPos.xy /= distortFactor;
    shadowPos.z *= 0.2;
    
    return shadowPos * 0.5 + 0.5;
}

vec3 SampleFilteredShadow(vec3 shadowPos, float offset) {
    float shadow0 = 0.0;

    for (int i = 0; i < 9; i++) {
        vec2 shadowOffset = shadowOffsets[i] * offset;
        shadow0 += shadow2D(shadowtex0, vec3(shadowPos.st + shadowOffset, shadowPos.z)).x;
    }
    shadow0 /= 9.0;

    vec3 shadowCol = vec3(0.0);
    #ifdef SHADOW_COLOR
    if (shadow0 < 0.999) {
        for (int i = 0; i < 9; i++) {
            vec2 shadowOffset = shadowOffsets[i] * offset;
            shadowCol += texture2D(shadowcolor0, shadowPos.st + shadowOffset).rgb *
                         shadow2D(shadowtex1, vec3(shadowPos.st + shadowOffset, shadowPos.z)).x;
        }
        shadowCol /= 9.0;
    }
    #endif

    return clamp(shadowCol * (1.0 - shadow0) + shadow0, vec3(0.0), vec3(1.0));
}

vec3 GetShadow(vec3 worldPos, float NoL) {
    vec3 shadowPos = calculateShadowPos(worldPos);

    bool doShadow = shadowPos.x > 0.0 && shadowPos.x < 1.0 &&
                    shadowPos.y > 0.0 && shadowPos.y < 1.0;

    float offset = float(SHADOW_BLUR_STRENGTH) / shadowMapResolution;

    vec3 shadow = SampleFilteredShadow(shadowPos, offset);

    return shadow;
}