uniform sampler2D shadowtex0, shadowtex1;

#ifdef SHADOW_COLOR
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

float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

#ifdef VPS
//Variable Penumbra Shadows based on Tech's Lux Shader (https://github.com/TechDevOnGitHub)
void findBlockerDistance(vec3 shadowPos, mat2 ditherMatrix, inout float offset, float skyLightMap, float viewDistance) {
    float blockerDistance = 0.0;
        
    for (int i = 0; i < 4; i++){
        vec2 pixelOffset = ditherMatrix * 0.015 * shadowOffsets4[i];
        blockerDistance += shadowPos.z - texture2D(shadowtex1, shadowPos.xy + pixelOffset).r;
    }
    blockerDistance *= 0.25;
    
    offset = mix(offset, clamp(blockerDistance * VPS_BLUR_STRENGTH, offset, offset * 12.0), skyLightMap * viewDistance);
}
#endif

vec3 computeShadow(vec3 shadowPos, float offset, float skyLightMap, float subsurface, float viewDistance) {
    vec3 shadowCol = vec3(0.0);
    float shadow0 = 0.0;

	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

    #ifdef TAA
    float dither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0)) * TAU;
    #else
    float dither = blueNoiseDither * TAU;
    #endif

	float cosTheta = cos(dither);
	float sinTheta = sin(dither);
	mat2 ditherMatrix = mat2(cosTheta, -sinTheta, sinTheta, cosTheta);

    #ifdef VPS
    if (subsurface < 0.1) findBlockerDistance(shadowPos, ditherMatrix, offset, skyLightMap, viewDistance);
    #endif

    for (int i = 0; i < 8; i++) {
        vec2 pixelOffset = ditherMatrix * offset * shadowOffsets8[i];
        shadow0 += texture2DShadow(shadowtex0, vec3(shadowPos.xy + pixelOffset, shadowPos.z));

        #ifdef SHADOW_COLOR
        if (shadow0 < 0.999) {
            shadowCol += texture2D(shadowcolor0, shadowPos.xy + pixelOffset).rgb *
                        texture2DShadow(shadowtex1, vec3(shadowPos.xy + pixelOffset, shadowPos.z));
        }
        #endif
    }
    shadow0 *= 0.125;
    shadowCol *= 0.125;

    return clamp(shadowCol * (1.0 - shadow0) + shadow0, 0.0, 1.0);
}

vec3 getFakeShadow(float skyLight) {
	float fakeShadow = 1.0;

	#if defined OVERWORLD || defined END
	skyLight = pow32(skyLight * skyLight);

    #ifdef END
    skyLight = 1.0;
    #endif
    
    #ifdef OVERWORLD
    skyLight *= float(isEyeInWater == 0);
    #endif

	fakeShadow = skyLight;
	#endif

	return vec3(fakeShadow);
}