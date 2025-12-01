uniform float framemod8;

vec2 jitterOffsets8[8] = vec2[8](
							vec2( 0.125,-0.375),
							vec2(-0.125, 0.375),
							vec2( 0.625, 0.125),
							vec2( 0.375,-0.625),
							vec2(-0.625, 0.625),
							vec2(-0.875,-0.125),
							vec2( 0.375,-0.875),
							vec2( 0.875, 0.875)
						);

vec2 TAAJitter(vec2 coord, float w) {
	vec2 offset = jitterOffsets8[int(framemod8)] * (w / vec2(viewWidth, viewHeight));
	#if !defined DH_WATER && !defined DH_TERRAIN
		 offset *= 0.5;
	#endif

	#if SOLAS_BY_SEPTONIOUS != 1
	offset *= 1984;
	#endif

	return coord + offset;
}