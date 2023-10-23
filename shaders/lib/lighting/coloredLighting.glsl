float getLinearDepth(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec2 offsetDist(float x) {
	float n = fract(x * 8.0) * 6.283;
    return vec2(cos(n), sin(n)) * x * x;
}

void computeColoredLighting(in float z0, inout vec3 coloredLighting, inout vec3 globalIllumination) {
    vec2 prvCoord = Reprojection(vec3(texCoord, z0));

    float emission = texture2D(colortex3, texCoord).a;
    float indirectEmission = float(emission > 0.094 && emission < 0.096);
    float directEmission = float(emission > 0.1 && emission <= 0.98) * (1.0 - indirectEmission);

    vec3 albedo = texture2D(colortex0, texCoord).rgb;

    #ifdef COLORED_LIGHTING
    vec3 clAlbedo = albedo * directEmission;
	vec3 previousColoredLight = vec3(0.0);
    #endif

    #ifdef GI
    vec3 giAlbedo = albedo * indirectEmission;
    vec3 previousGlobalIllumination = vec3(0.0);
    #endif

    if (prvCoord.x > 0.0 && prvCoord.x < 1.0 && prvCoord.y > 0.0 && prvCoord.y < 1.0) {
        float linearDepth0 = getLinearDepth(z0);
        float fovScale = gbufferProjection[1][1] / 1.37;
        float distScale = clamp((far - near) * linearDepth0 + near, 0.0, 128.0);
        float dither = fract(Bayer64(gl_FragCoord.xy) + frameCounter * 1.618);

        vec2 blurRadius = vec2(1.0 / aspectRatio, 1.0) * fovScale;

        vec2 directLightingRadius = blurRadius * COLORED_LIGHTING_RADIUS / distScale;
        vec2 indirectLightingRadius = blurRadius * GLOBAL_ILLUMINATION_RADIUS / distScale;

        for (int i = 0; i < 4; i++) {
            #ifdef COLORED_LIGHTING
            vec2 blurOffsetCL = offsetDist((dither + i) * 0.25);
                 blurOffsetCL = floor(blurOffsetCL * vec2(viewWidth, viewHeight) + 0.5) / vec2(viewWidth, viewHeight);
            vec2 directLightingOffset = blurOffsetCL * directLightingRadius;
            previousColoredLight += texture2D(colortex4, prvCoord.xy + directLightingOffset).rgb;
            #endif

            #ifdef GI
            vec2 blurOffsetGI = offsetDist((dither + i) * 0.15);
            vec2 indirectLightingOffset = blurOffsetGI * indirectLightingRadius;
            previousGlobalIllumination += texture2D(colortex5, prvCoord.xy + indirectLightingOffset).rgb;
            #endif
        }

        #ifdef COLORED_LIGHTING
        previousColoredLight *= 0.25;
        previousColoredLight *= previousColoredLight;
        #endif

        #ifdef GI
        previousGlobalIllumination *= 0.25;
        previousGlobalIllumination *= previousGlobalIllumination;
        #endif
    }

    #ifdef COLORED_LIGHTING
	coloredLighting = sqrt(mix(previousColoredLight, clAlbedo, 0.01));
    #endif

    #ifdef GI
	globalIllumination = sqrt(mix(previousGlobalIllumination, giAlbedo, 0.01));
    #endif
}