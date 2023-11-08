void getReflection(inout vec4 color, in vec3 viewPos, in vec3 normal, in float fresnel, in float reflectivity) {
	float border = 0.0;
	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + frameCounter * 0.618);
	#endif

	vec3 reflectPos = rayTrace(depthtex0, viewPos, normal, blueNoiseDither, border, 6, 10, 0.1, 2.0);

	border = clamp(13.333 * (1.0 - border), 0.0, 1.0);

	vec4 reflection = texture2DLod(colortex0, reflectPos.xy, 2.0 * (1.0 - reflectivity));
		 reflection.a *= border;

	vec3 finalReflection = max(mix(vec3(0.0), reflection.rgb, reflection.a), vec3(0.0));

	color.rgb = mix(color.rgb, finalReflection, fresnel);
}