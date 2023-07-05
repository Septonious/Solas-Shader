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
    float directEmission = float(emission > 0.1);
    float indirectEmission = float(emission > 0.05 && emission < 0.1);
    vec3 albedo = texture2D(colortex0, texCoord).rgb;
    vec3 lightAlbedo = albedo * directEmission;
    vec3 giAlbedo = albedo * indirectEmission;
	vec3 previousColoredLight = vec3(0.0);
    vec3 previousGlobalIllumination = vec3(0.0);

    if (prvCoord.x > 0.0 && prvCoord.x < 1.0 && prvCoord.y > 0.0 && prvCoord.y < 1.0) {
        float linearDepth0 = getLinearDepth(z0);
        float fovScale = gbufferProjection[1][1] / 1.37;
        float distScale = clamp((far - near) * linearDepth0 + near, 4.0, 128.0);
        float dither = fract(Bayer64(gl_FragCoord.xy) + frameCounter * 1.618);

        vec2 blurRadius = vec2(1.0 / aspectRatio, 1.0) * fovScale;

        #ifdef COLORED_LIGHTING
        vec2 directLightingRadius = blurRadius * COLORED_LIGHTING_RADIUS / distScale;
        #endif

        #ifdef GLOBAL_ILLUMINATION
        vec2 indirectLightingRadius = blurRadius * GLOBAL_ILLUMINATION_RADIUS / distScale;
        #endif

        for (int i = 0; i < 4; i++) {
            vec2 blurOffset = offsetDist((dither + i) * 0.25);

            #ifdef COLORED_LIGHTING
            vec2 directLightingOffset = blurOffset * directLightingRadius;
            previousColoredLight += texture2D(colortex4, prvCoord.xy + directLightingOffset).rgb;
            #endif

            #ifdef GLOBAL_ILLUMINATION
            vec2 indirectLightingOffset = blurOffset * indirectLightingRadius;
            previousGlobalIllumination += texture2D(colortex5, prvCoord.xy + indirectLightingOffset).rgb;
            #endif
        }

        #ifdef COLORED_LIGHTING
        previousColoredLight *= 0.25;
        previousColoredLight *= previousColoredLight;
        #endif

        #ifdef GLOBAL_ILLUMINATION
        previousGlobalIllumination *= 0.25;
        previousGlobalIllumination *= previousGlobalIllumination;
        #endif
    }

    #ifdef COLORED_LIGHTING
	coloredLighting = sqrt(mix(previousColoredLight, lightAlbedo, 0.05));
    #endif

    #ifdef GLOBAL_ILLUMINATION
    globalIllumination = sqrt(mix(previousGlobalIllumination, giAlbedo, 0.05));
    #endif
}