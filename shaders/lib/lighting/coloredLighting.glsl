float getLinearDepth(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec2 offsetDist(float x) {
	float n = fract(x * 8.0) * 6.283;
    return vec2(cos(n), sin(n)) * x * x;
}

void computeColoredLighting(in float z0, inout vec3 coloredLighting) {
    vec2 prvCoord = Reprojection(vec3(texCoord, z0));

    float emission = texture2D(colortex3, texCoord).a;
    float directEmission = float(emission > 0.1 && emission <= 0.98);
    vec3 albedo = texture2D(colortex0, texCoord).rgb * directEmission;
	vec3 previousColoredLight = vec3(0.0);

    if (prvCoord.x > 0.0 && prvCoord.x < 1.0 && prvCoord.y > 0.0 && prvCoord.y < 1.0) {
        float linearDepth0 = getLinearDepth(z0);
        float fovScale = gbufferProjection[1][1] / 1.37;
        float distScale = clamp((far - near) * linearDepth0 + near, 0.0, 128.0);
        float dither = fract(Bayer64(gl_FragCoord.xy) + frameCounter * 1.618);

        vec2 blurRadius = vec2(1.0 / aspectRatio, 1.0) * fovScale;

        #ifdef COLORED_LIGHTING
        vec2 directLightingRadius = blurRadius * COLORED_LIGHTING_RADIUS / distScale;
        #endif

        for (int i = 0; i < 4; i++) {
            vec2 blurOffset = offsetDist((dither + i) * 0.25);

            #ifdef COLORED_LIGHTING
            vec2 directLightingOffset = blurOffset * directLightingRadius;
            previousColoredLight += texture2D(colortex4, prvCoord.xy + directLightingOffset).rgb;
            #endif
        }

        #ifdef COLORED_LIGHTING
        previousColoredLight *= 0.25;
        previousColoredLight *= previousColoredLight;
        #endif
    }

    #ifdef COLORED_LIGHTING
	coloredLighting = sqrt(mix(previousColoredLight, albedo, 0.01));
    #endif
}