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

vec3 sampleFilteredShadow(vec3 shadowPos, float offset, float dither) {
    float shadow0 = 0.0;

    for (int i = 0; i < SHADOW_SAMPLE_COUNT; i++) {
        vec2 shadowOffset = offsetDist(float(i + dither)) * offset;
        shadow0 += shadow2D(shadowtex0, vec3(shadowPos.st + shadowOffset, shadowPos.z)).x;
    }
    shadow0 /= SHADOW_SAMPLE_COUNT;

    vec3 shadowCol = vec3(0.0);
    #ifdef SHADOW_COLOR
    if (shadow0 < 0.999) {
        for (int i = 0; i < SHADOW_SAMPLE_COUNT; i++) {
            vec2 shadowOffset = offsetDist(float(i + dither)) * offset;
            shadowCol += texture2D(shadowcolor0, shadowPos.st + shadowOffset).rgb *
                         shadow2D(shadowtex1, vec3(shadowPos.st + shadowOffset, shadowPos.z)).x;
        }
        shadowCol /= SHADOW_SAMPLE_COUNT;
    }
    #endif

    return clamp(shadowCol * (1.0 - shadow0) + shadow0, 0.0, 1.0);
}