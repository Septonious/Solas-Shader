#ifdef REALTIME_SHADOWS
uniform sampler2D shadowtex0;

#ifdef SHADOW_COLOR
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
#endif

float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

vec2 offsetDist(float x, int s) {
    float n = fract(x * 2.427) * 3.1415;
    return vec2(cos(n), sin(n)) * 1.4 * x / s;
}

vec3 SampleShadow(vec3 shadowPos) {
    float shadow0 = texture2DShadow(shadowtex0, shadowPos);

    float doShadowColor = 1.0;
    #ifdef OVERWORLD
          doShadowColor -= wetness;
    #endif

    vec3 shadowColor = vec3(0.0);
    if (shadow0 < 1.0 && doShadowColor > 0.9) {
        float shadow1 = texture2DShadow(shadowtex1, shadowPos);
        if (shadow1 > 0.9999) {
            shadowColor = texture2D(shadowcolor0, shadowPos.st).rgb * shadow1;
        }
    }

    return shadowColor * doShadowColor * (1.0 - shadow0) + shadow0;
}

void computeShadow(inout vec3 shadow, vec3 shadowPos, float offset, float subsurface, float skyLightMap) {
    float shadow0 = 0.0;
    vec3 shadowColor = vec3(0.0);    

    float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;
    #ifdef TAA
         blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
    #endif

    if (subsurface < 0.01) {
        int shadowSamples = 2;

        for (int i = 0; i < shadowSamples; i++) {
            vec2 shadowOffset = offsetDist(blueNoiseDither + i, shadowSamples) * offset;
            shadow += SampleShadow(vec3(shadowPos.st + shadowOffset, shadowPos.z));
            shadow += SampleShadow(vec3(shadowPos.st - shadowOffset, shadowPos.z));
        }

        shadow /= shadowSamples * 2.0;
    } else {
        float distb = sqrt(dot(shadowPos.xy, shadowPos.xy));
        float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);

        vec3 offsetScale = vec3(0.002 / distortFactor, 0.002 / distortFactor, 0.001) * (subsurface * 0.75 + 0.25);

        for(int i = 0; i < 12; i++) {
            blueNoiseDither = fract(blueNoiseDither + 1.618);
            float rot = blueNoiseDither * 6.283;
            float dist = (i + blueNoiseDither) / 12.0;

            vec2 offset2D = vec2(cos(rot), sin(rot)) * dist;
            float offsetZ = -(dist * dist + 0.025) * 0.25;

            vec3 offset = vec3(offset2D, offsetZ) * offsetScale;

            vec3 samplePos = shadowPos + offset;
            shadow += SampleShadow(samplePos);
        }
        shadow /= 12.0;
    }
}
#endif

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