uniform sampler2DShadow shadowtex0;

#if defined SHADOW_COLOR || defined VPS
uniform sampler2D shadowtex1;
#endif

#ifdef SHADOW_COLOR
uniform sampler2D shadowcolor0;
#endif

vec3 calculateShadowPos(vec3 worldPos) {
    vec3 shadowPos = ToShadow(worldPos);
    float distb = sqrt(shadowPos.x * shadowPos.x + shadowPos.y * shadowPos.y);
    float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);

    shadowPos.xy /= distortFactor;
    shadowPos.z *= 0.2;
    
    return shadowPos * 0.5 + 0.5;
}

vec2 offsetDist(float x) {
	float n = fract(x * 8.0) * PI;

    return vec2(cos(n), sin(n)) * x;
}

float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    return step(shadowPos.z - 0.0001, texture2D(shadowtex, shadowPos.xy).r);
}

#ifdef VPS
//Variable Penumbra Shadows based on Tech's Lux Shader (https://github.com/TechDevOnGitHub)
void findBlockerDistance(vec3 shadowPos, in float dither, inout float offset, float skyLightMap) {
    float blockerDistance = 0.0;
        
    for (int i = 0; i < 4; i++){
        vec2 pixelOffset = offsetDist(i + dither) * offset * 4.0;
        blockerDistance += shadowPos.z - texture2D(shadowtex1, shadowPos.xy + pixelOffset).r;
    }
    blockerDistance *= 0.25;

    offset = mix(offset, max(offset, min(blockerDistance * VPS_BLUR_STRENGTH, offset * 6.0)), skyLightMap);
}
#endif

vec3 computeShadow(vec3 shadowPos, float offset, float dither, float skyLightMap, float ao, float subsurface) {
    float shadow0 = 0.0;

    #ifdef VPS
    if (subsurface < 0.5) findBlockerDistance(shadowPos, dither, offset, skyLightMap);
    #endif

    for (int i = 0; i < 4; i++) {
        vec2 pixelOffset = offsetDist(i + dither) * offset;
        shadow0 += shadow2D(shadowtex0, vec3(shadowPos.st + pixelOffset, shadowPos.z)).r;
    }
    shadow0 *= 0.25;

    vec3 shadowCol = vec3(0.0);
    #ifdef SHADOW_COLOR
    if (shadow0 < 0.999) {
        for (int i = 0; i < 4; i++) {
            vec2 pixelOffset = offsetDist(i + dither) * offset;
            shadowCol += texture2D(shadowcolor0, shadowPos.st + pixelOffset).rgb *
                         texture2DShadow(shadowtex1, vec3(shadowPos.st + pixelOffset, shadowPos.z));
        }
        shadowCol *= 0.25;
    }
    #endif

    //Light leak fix
    if (skyLightMap < 0.01) shadow0 = mix(shadow0, shadow0 * ao, (1.0 - ao));

    return clamp(shadowCol * (1.0 - shadow0) + shadow0, 0.0, 1.0);
}