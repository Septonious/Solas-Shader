void getReflection(in vec3 viewPos, in vec3 normal, inout vec3 color, in float fresnel) {
	float border = 0.0;
	float dither = Bayer64(gl_FragCoord.xy);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

	vec3 reflectPos = rayTrace(viewPos, normal, dither, border, 4, 1.0, 0.1, 2.0);
	vec4 reflection = vec4(0.0);

	if (reflectPos.z < 1.0 - 1e-5) {
		reflection.a = texture2D(colortex6, reflectPos.xy).a;
		if (reflection.a > 0.001) {
			reflection.rgb = texture2D(colortex6, reflectPos.xy).rgb;
			reflection.rgb = pow(reflection.rgb, vec3(2.2));
		}
	}

	vec3 finalReflection = max(mix(color, reflection.rgb, reflection.a), vec3(0.0));
			
	color.rgb = mix(color.rgb, finalReflection, fresnel);
}