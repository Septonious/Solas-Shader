uniform sampler2D shadowtex0;

#ifdef SHADOW_COLOR
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
#endif

int shadowFilterSamples = 8;

vec2 shadowOffsets[8] = vec2[8](
    vec2(  0.000000,  0.250000 ),
    vec2(  0.292496, -0.319290 ),
    vec2( -0.556877,  0.048872 ),
    vec2(  0.524917,  0.402445 ),
    vec2( -0.130636, -0.738535 ),
    vec2( -0.445032,  0.699604 ),
    vec2(  0.870484, -0.234003 ),
    vec2( -0.859268, -0.446273 )
);

vec3 calculateShadowPos(vec3 worldPos) {
    vec3 shadowPos = ToShadow(worldPos);
    float distb = sqrt(shadowPos.x * shadowPos.x + shadowPos.y * shadowPos.y);
    float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);

    shadowPos.xy /= distortFactor;
    shadowPos.z *= 0.2;
    
    return shadowPos * 0.5 + 0.5;
}

mat2 Rotate(float angle) {
    float sinAngle = sin(angle);
    float cosAngle = cos(angle);
    return mat2(cosAngle, -sinAngle, sinAngle, cosAngle);
}

float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

#ifdef VPS
//Variable Penumbra Shadows based on Tech's Lux Shader (https://github.com/TechDevOnGitHub)
float findBlockerDistance(vec3 shadowPos, float offset, mat2 ditherRotMat) {
    float blockerDistance = 0.0;
        
    for (int i = 0; i < shadowFilterSamples; i++){
        vec2 offset = ditherRotMat * shadowOffsets[i] * 0.015;
        blockerDistance += shadowPos.z - texture2D(shadowtex0, shadowPos.xy + offset).x;
    }
    blockerDistance /= shadowFilterSamples;

    return max(offset, blockerDistance * 0.3);
}
#endif

vec3 computeShadow(vec3 shadowPos, float offset, float dither) {
    float shadow0 = 0.0;

    mat2 ditherRotMat = Rotate(dither * TAU);

    #ifdef VPS
    offset = findBlockerDistance(shadowPos, offset, ditherRotMat);
    #endif

    for (int i = 0; i < shadowFilterSamples; i++) {
        vec2 shadowOffset = ditherRotMat * shadowOffsets[i] * offset;
        shadow0 += texture2DShadow(shadowtex0, vec3(shadowPos.st + ditherRotMat * shadowOffsets[i] * offset, shadowPos.z));
    }
    shadow0 /= shadowFilterSamples;

    vec3 shadowCol = vec3(0.0);
    #ifdef SHADOW_COLOR
    if (shadow0 < 0.999) {
        for (int i = 0; i < shadowFilterSamples; i++) {
            vec2 shadowOffset = ditherRotMat * shadowOffsets[i] * offset;
            shadowCol += texture2D(shadowcolor0, shadowPos.st + shadowOffset).rgb *
                         texture2DShadow(shadowtex1, vec3(shadowPos.st + ditherRotMat * shadowOffsets[i] * offset, shadowPos.z));
        }
        shadowCol /= shadowFilterSamples;
    }
    #endif

    return clamp(shadowCol * (1.0 - shadow0) + shadow0, 0.0, 1.0);
}