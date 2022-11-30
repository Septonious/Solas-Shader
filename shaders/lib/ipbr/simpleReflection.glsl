void getReflection(inout vec4 color, in vec3 viewPos, in vec3 normal, in float fresnel) {
	float border = 0.0;
	float dither = Bayer64(gl_FragCoord.xy);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

	vec3 reflectPos = rayTrace(viewPos, normal, dither, border, 8, 1.0, 0.1, 2.0);
	vec4 reflection = vec4(0.0);

	border = clamp(13.333 * (1.0 - border), 0.0, 1.0);

	if (reflectPos.z < 1.0 - 1e-5) {
		reflection.a = texture2D(colortex0, reflectPos.xy).a;
		if (reflection.a > 0.001) {
			reflection.rgb = texture2D(colortex0, reflectPos.xy).rgb;
		}
		reflection.a *= border;
	}

	color.rgb = mix(color.rgb, max(mix(vec3(0.0), reflection.rgb, reflection.a), vec3(0.0)), fresnel);
	color.a = mix(color.a, 1.0, fresnel);
}