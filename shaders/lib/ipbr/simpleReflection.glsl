void getReflection(in vec3 viewPos, in vec3 normal, inout vec3 color, in float fresnel) {
	float border = 0.0;
	float dither = Bayer64(gl_FragCoord.xy);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

	vec3 reflectPos = rayTrace(viewPos, normal, dither, border, 8, 1.0, 0.1, 2.0);
	vec3 reflection = texture2D(colortex0, reflectPos.xy).rgb;
		
	color.rgb = mix(color.rgb, max(reflection.rgb, vec3(0.0)), fresnel);
}