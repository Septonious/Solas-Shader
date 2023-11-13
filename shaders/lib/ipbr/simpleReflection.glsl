void getReflection(inout vec4 color, in vec3 viewPos, in vec3 normal, in float fresnel, in float smoothness) {
	float border = 0.0;
	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + frameCounter * 0.618);
	#endif

	vec4 reflectPos = rayTrace(depthtex0, viewPos, normal, blueNoiseDither, border, 6, 10, 0.1, 2.0);

	border = clamp(13.333 * (1.0 - border) * (0.9 * smoothness + 0.1), 0.0, 1.0);

	#ifdef PBR
	float fovScale = gbufferProjection[1][1] / 1.37;
	float dist = 0.1 * pow2(1.0 - smoothness) * reflectPos.a * fovScale;
	float lod = log2(viewHeight * dist);
	#else
	float lod = 3.0 * (1.0 - smoothness);
	#endif

	vec4 reflection = texture2DLod(colortex0, reflectPos.xy, lod);
		 reflection.a *= border;

	vec3 finalReflection = max(mix(vec3(0.0), reflection.rgb, reflection.a), vec3(0.0));

	color.rgb = mix(color.rgb, finalReflection, fresnel);
}