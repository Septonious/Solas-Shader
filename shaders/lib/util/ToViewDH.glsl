vec3 ToViewDH(vec2 texCoord, float z, float dhZ) {
	vec4 viewPos = vec4(0.0);
	vec4 iProjDiag = vec4(0.0);
    vec3 pos = vec3(0.0);

	#ifdef DISTANT_HORIZONS
    	if (z < 1.0) {
	#endif
            iProjDiag = vec4(gbufferProjectionInverse[0].x,
                             gbufferProjectionInverse[1].y,
                             gbufferProjectionInverse[2].zw);

    		pos = vec3(texCoord, z) * 2.0 - 1.0;
    		viewPos = iProjDiag * pos.xyzz + gbufferProjectionInverse[3];
			viewPos.xyz /= viewPos.w;
	#ifdef DISTANT_HORIZONS
		} else {
			iProjDiag = vec4(dhProjectionInverse[0].x,
                             dhProjectionInverse[1].y,
                             dhProjectionInverse[2].zw);

    		pos = vec3(texCoord, dhZ) * 2.0 - 1.0;
    		viewPos = iProjDiag * pos.xyzz + dhProjectionInverse[3];
			viewPos.xyz /= viewPos.w;
		}
	#endif

    return viewPos.xyz;
}