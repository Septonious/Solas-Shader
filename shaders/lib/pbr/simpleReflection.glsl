void getReflection(inout vec4 color, in vec3 viewPos, in vec3 normal, in float fresnel, in float smoothness) {
	float border = 0.0;
	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif

	vec3 falloff = vec3(0.0);
	vec4 reflectPos = rayTrace(depthtex1, viewPos, normal, blueNoiseDither, fresnel, border, 6, 20, 0.1, 2.0);

	border = clamp(13.333 * (1.0 - border), 0.0, 1.0);

	if (reflectPos.z < 1.0 - 1e-5) {
		#ifdef OVERWORLD
		vec3 skyRefPos = reflect(normalize(viewPos), normal);
		vec3 sunPos = vec3(gbufferModelViewInverse * vec4(sunVec * 128.0, 1.0));
		vec3 sunCoord = sunPos / (sunPos.y + length(sunPos.xz));
		falloff = getAtmosphericScattering(skyRefPos, normalize(sunCoord)) * pow4(eBS);
		falloff *= falloff;

		#if MC_VERSION >= 11900
		falloff *= 1.0 - darknessFactor;
		#endif

		falloff *= 1.0 - blindFactor;
		#endif

		float dist = 1.0 - exp(-0.2 * (1.0 - smoothness * smoothness) * reflectPos.a);
		float lod = log2(viewHeight / 8.0 * (1.0 - smoothness * smoothness) * dist);

		vec4 reflection = texture2DLod(colortex0, reflectPos.xy, max(lod - 1.0, 0.0));
		reflection.a *= border;

		color.rgb = mix(color.rgb, mix(falloff, reflection.rgb, reflection.a), fresnel);
	}
}