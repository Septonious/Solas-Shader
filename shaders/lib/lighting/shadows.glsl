uniform sampler2DShadow shadowtex0;

#ifdef SHADOW_COLOR
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
#endif

const vec2 shadowOffsets4[4] = vec2[4](
   vec2(0.21848650099008202, -0.09211370200809937),
   vec2(-0.5866112654782878, 0.32153793477769893),
   vec2(-0.06595078555407359, -0.879656059066481),
   vec2(0.43407555004227927, 0.6502318262968816)
);

const vec2 shadowOffsets8[8] = vec2[8](
   vec2(0.2921473492144121, 0.03798942536906266),
   vec2(-0.27714274097351554, 0.3304853027892154),
   vec2(0.09101981507673855, -0.5188871157785563),
   vec2(0.44459182774878003, 0.5629069824170247),
   vec2(-0.6963877647721594, -0.09264703741542105),
   vec2(0.7417522811565185, -0.4070419658858473),
   vec2(-0.191856808948964, 0.9084732299066597),
   vec2(-0.40412395850181015, -0.8212788214021378)
);

vec3 calculateShadowPos(vec3 worldPos) {
    vec3 shadowPos = ToShadow(worldPos);
    float distb = sqrt(shadowPos.x * shadowPos.x + shadowPos.y * shadowPos.y);
    float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);

    shadowPos.xy /= distortFactor;
    shadowPos.z *= 0.2;
    
    return shadowPos * 0.5 + 0.5;
}

float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.st).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

#ifdef VPS
//Variable Penumbra Shadows based on Tech's Lux Shader (https://github.com/TechDevOnGitHub)
void findBlockerDistance(vec3 shadowPos, mat2 ditherMatrix, inout float offset, float skyLightMap, float viewLengthFactor) {
    float blockerDistance = 0.0;
        
    for (int i = 0; i < 4; i++){
        vec2 pixelOffset = ditherMatrix * shadowOffsets4[i] * 0.015;
        blockerDistance += shadowPos.z - texture2D(shadowtex1, shadowPos.xy + pixelOffset).r;
    }
    blockerDistance *= 0.25;
    
    offset = mix(offset, clamp(blockerDistance * VPS_BLUR_STRENGTH, offset, offset * 16.0), skyLightMap * viewLengthFactor);
}
#endif

vec3 computeShadow(vec3 shadowPos, float offset, float dither, float skyLightMap, float ao, float subsurface, float viewLengthFactor) {
    vec3 shadowCol = vec3(0.0);
    float shadow0 = 0.0;

	float cosTheta = cos(dither);
	float sinTheta = sin(dither);
	mat2 ditherMatrix = mat2(cosTheta, -sinTheta, sinTheta, cosTheta);

    #ifdef VPS
    if (subsurface < 0.1) findBlockerDistance(shadowPos, ditherMatrix, offset, skyLightMap, viewLengthFactor);
    #endif

    for (int i = 0; i < 8; i++) {
        vec2 pixelOffset = ditherMatrix * shadowOffsets8[i] * offset;
        shadow0 += shadow2D(shadowtex0, vec3(shadowPos.st + pixelOffset, shadowPos.z)).r;

        #ifdef SHADOW_COLOR
        if (shadow0 < 0.999) {
            shadowCol += texture2D(shadowcolor0, shadowPos.st + pixelOffset).rgb *
                        texture2DShadow(shadowtex1, vec3(shadowPos.st + pixelOffset, shadowPos.z));
        }
        #endif
    }
    shadow0 *= 0.125;
    shadowCol *= 0.125;

    //Light leak fix
    shadow0 = mix(shadow0, shadow0 * ao, (1.0 - ao));

    return clamp(shadowCol * (1.0 - shadow0) + shadow0, 0.0, 1.0);
}