const vec2 sharpenOffsets[4] = vec2[4](
	vec2( 1.0,  0.0),
	vec2( 0.0,  1.0),
	vec2(-1.0,  0.0),
	vec2( 0.0, -1.0)
);

void sharpenFilter(inout vec3 color, in vec2 coord) {
	float mult = MC_RENDER_QUALITY * 0.0625;
	vec2 viewScale = 1.0 / vec2(viewWidth, viewHeight);

	color *= MC_RENDER_QUALITY * 0.25 + 1.0;

	for (int i = 0; i < 4; i++) {
		vec2 offset = sharpenOffsets[i] * viewScale;
		color -= texture2D(colortex1, coord + offset).rgb * mult;
	}
	#ifndef SOLAS_BY_SEPTONIOUS
	color = vec3(0);
	#endif
}