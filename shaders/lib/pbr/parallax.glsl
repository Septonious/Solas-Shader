vec4 readNormal(vec2 coord) {
    coord = fract(coord) * vTexCoordAM.pq + vTexCoordAM.st;
	return texture2DGradARB(normals, coord, dcdx, dcdy);
}

vec2 getParallaxCoord(vec2 texCoord, float parallaxFade, out float surfaceDepth) {
    vec2 coord = vTexCoord.st;
    surfaceDepth = 1.0;

    if (viewVector != viewVector) {
        return texCoord;
    }

    float dither = Bayer8(gl_FragCoord.xy);

    #ifdef TAA
    dither = fract(dither + frameTimeCounter * 16.0);
    #endif

    float sampleStep = (dither * 0.4 + 0.6) / PARALLAX_QUALITY;
    float currentStep = 1.0;

    vec2 scaledDir = viewVector.xy * PARALLAX_DEPTH / -viewVector.z;
    vec2 stepDir = scaledDir * sampleStep * (1.0 - parallaxFade);

    vec3 normalMap = readNormal(coord).xyz * 2.0 - 1.0;
    float normalCheck = normalMap.x + normalMap.y;
    if (parallaxFade >= 1.0 || normalCheck < -1.999) return texCoord;

    float depth = readNormal(coord).a;

    for (int i = 0; i < PARALLAX_QUALITY; i++){
        if (currentStep <= depth) break;
        coord += stepDir;
        depth = readNormal(coord).a;
        currentStep -= sampleStep;
    }

    coord = fract(coord.st) * vTexCoordAM.pq + vTexCoordAM.st;
    surfaceDepth = currentStep;

    return coord;
}

float getParallaxShadow(float surfaceDepth, float parallaxFade, vec2 coord, vec3 lightVec, mat3 tbn) {
    float parallaxshadow = 1.0;
    if (parallaxFade >= 1.0) return 1.0;

    float height = surfaceDepth;
    if (height > 1.0 - 0.5 / PARALLAX_QUALITY) return 1.0;

    float dither = Bayer8(gl_FragCoord.xy);

    #ifdef TAA
    dither = fract(dither + frameTimeCounter * 16.0);
    #endif

    vec3 parallaxDir = tbn * lightVec;
         parallaxDir.xy *= PARALLAX_DEPTH * SELF_SHADOW_ANGLE;
    vec2 newvTexCoord = (coord - vTexCoordAM.st) / vTexCoordAM.pq;
    float sampleStep = (dither * 0.2 + 0.2) / SELF_SHADOW_QUALITY;

    vec2 ptexCoord = fract(newvTexCoord + parallaxDir.xy * sampleStep) * 
                     vTexCoordAM.pq + vTexCoordAM.st;

    float texHeight = texture2DGradARB(normals, coord, dcdx, dcdy).a;
    float texHeightOffset = texture2DGradARB(normals, ptexCoord, dcdx, dcdy).a;
    float texFactor = clamp((height - texHeightOffset) / sampleStep + 1.0, 0.0, 1.0);

    height = mix(height, texHeight, texFactor);
    
    for (int i = 0; i < SELF_SHADOW_QUALITY; i++) {
        float currentHeight = height + parallaxDir.z * sampleStep * i;

        vec2 parallaxCoord = fract(newvTexCoord + parallaxDir.xy * i * sampleStep) * 
                             vTexCoordAM.pq + vTexCoordAM.st;

        float offsetHeight = texture2DGradARB(normals, parallaxCoord, dcdx, dcdy).a;
        float sampleShadow = clamp(1.0 - (offsetHeight - currentHeight) * SELF_SHADOW_STRENGTH, 0.0, 1.0);

        parallaxshadow = min(parallaxshadow, sampleShadow);

        if (parallaxshadow < 0.01) break;
    }

    parallaxshadow *= parallaxshadow;
    parallaxshadow = mix(parallaxshadow, 1.0, parallaxFade);

    return parallaxshadow;
}