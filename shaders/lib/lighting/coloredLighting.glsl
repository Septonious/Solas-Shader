float getLinearDepth(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec2 offsetDist(float x) {
	float n = fract(x * 8.0) * 6.283;
    return vec2(cos(n), sin(n)) * x * x;
}

void computeColoredLighting(in float z, inout vec3 coloredLighting, inout vec3 globalIllumination) {
	vec2 prvCoord = Reprojection(vec3(texCoord, z));
	float linearDepth = getLinearDepth(z);

	float distScaleCL = clamp((far - near) * linearDepth + near, 2.0, 96.0);
    float distScaleGI = clamp((far - near) * linearDepth + near, 2.0, 32.0);
	float fovScale = gbufferProjection[1][1] / 1.37;

	vec2 directBlurStrength = vec2(1.0 / aspectRatio, 1.0) * COLORED_LIGHTING_RADIUS * fovScale / distScaleCL;
    vec2 indirectBlurStrength = vec2(1.0 / aspectRatio, 1.0) * GLOBAL_ILLUMINATION_RADIUS * fovScale / distScaleGI;
	
    float emission = texture2D(colortex3, texCoord).a;
    float indirectEmission = float(emission > 0.094 && emission < 0.096);
    float directEmission = float(emission > 0.1 && emission <= 0.98) * (1.0 - indirectEmission) * emission;

    vec3 albedo = texture2D(colortex0, texCoord).rgb;

    #ifdef COLORED_LIGHTING
    vec3 clAlbedo = albedo * albedo * directEmission;
	vec3 previousColoredLight = vec3(0.0);
    #endif

    #ifdef GI
    vec3 giAlbedo = albedo * albedo * indirectEmission;
    vec3 previousGlobalIllumination = vec3(0.0);
    #endif

	float mask = clamp(2.0 - 2.0 * max(abs(prvCoord.x - 0.5), abs(prvCoord.y - 0.5)), 0.0, 1.0);

	if (mask > 0.0) {
		float dither = Bayer64(gl_FragCoord.xy);

		#ifdef TAA
		dither = fract(dither + frameCounter * 1.618);
		#endif

		for (int i = 0; i < 4; i++) {
			#ifdef COLORED_LIGHTING
			vec2 clOffset = offsetDist((dither + i) * 0.25) * directBlurStrength;
				 clOffset = floor(clOffset * vec2(viewWidth, viewHeight) + 0.5) / vec2(viewWidth, viewHeight);

			vec2 sampleZPos = texCoord + clOffset;
			float sampleZ0 = texture2D(depthtex0, sampleZPos).r;
			float sampleZ1 = texture2D(depthtex1, sampleZPos).r;
			float linearSampleZ = getLinearDepth(sampleZ1 >= 1.0 ? sampleZ0 : sampleZ1);

			float sampleWeight = clamp(abs(linearDepth - linearSampleZ) * far / 16.0, 0.0, 1.0);
				  sampleWeight = 1.0 - sampleWeight * sampleWeight;

			previousColoredLight += texture2D(colortex4, prvCoord.xy + clOffset).rgb * sampleWeight;
			#endif

			#ifdef GI
			vec2 giOffset = offsetDist((dither + i) * 0.25) * indirectBlurStrength;
				 giOffset = floor(giOffset * vec2(viewWidth, viewHeight) + 0.5) / vec2(viewWidth, viewHeight);

			previousGlobalIllumination += texture2D(colortex5, prvCoord.xy + giOffset).rgb;
			#endif
		}

		#ifdef COLORED_LIGHTING
		previousColoredLight *= 0.25;
		previousColoredLight *= previousColoredLight * mask;
		coloredLighting = sqrt(mix(previousColoredLight, clAlbedo * 10.0, 0.1));
		#endif

		#ifdef GI
		previousGlobalIllumination *= 0.25;
		previousGlobalIllumination *= previousGlobalIllumination * mask;
		globalIllumination = sqrt(mix(previousGlobalIllumination, giAlbedo * 10.0, 0.1));
		#endif
	}
}