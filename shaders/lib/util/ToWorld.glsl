vec3 ToWorld(vec3 viewPos) {
	#ifndef SOLAS_BY_SEPTONIOUS
	return vec3(0);
	#endif

	return mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;
}