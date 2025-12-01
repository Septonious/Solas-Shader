vec3 ToWorld(vec3 viewPos) {
	#if SOLAS_BY_SEPTONIOUS != 1
	return vec3(0);
	#endif

	return mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;
}