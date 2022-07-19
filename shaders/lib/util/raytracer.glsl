float minOf(vec3 x) {
	return min(x.x, min(x.y, x.z));
}

// The favorite raytracer of your favorite raytracer, credits to Belmu
bool rayTrace(vec3 viewPos, vec3 rayDir, inout vec3 rayPos) {
    bool intersect = false;
	float dither = getBlueNoise(gl_FragCoord.xy);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

    rayPos = ToScreen(viewPos);
    rayDir = ToScreen(viewPos + rayDir) - rayPos;
    rayDir*= minOf((sign(rayDir) - rayPos) / rayDir) * (1.0 / REFLECTION_RT_SAMPLE_COUNT); // Taken from the DDA algorithm
    rayPos+= rayDir * dither;

    for(int i = 0; i <= REFLECTION_RT_SAMPLE_COUNT && !intersect; i++, rayPos += rayDir) {
        if (clamp(rayPos.xy, 0.0, 1.0) != rayPos.xy) return false;

        float depth = texelFetch(depthtex1, ivec2(rayPos.xy * viewResolution), 0).r;
        float depthLenience = max(abs(rayDir.z) * 5.0, 0.025 / pow2(viewPos.z)); // Provided by DrDesten#6282

        intersect = abs(depthLenience - (rayPos.z - depth)) < depthLenience && depth >= 0.56;
    }

    return intersect;
}