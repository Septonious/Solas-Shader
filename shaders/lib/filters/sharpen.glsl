vec2 sharpenOffsets[4] = vec2[4](
	vec2( 1.0,  0.0),
	vec2( 0.0,  1.0),
	vec2(-1.0,  0.0),
	vec2( 0.0, -1.0)
);

void sharpenFilter(inout vec4 color, in vec2 coord, in sampler2D colortex, in float multiplier) {
	float weight = multiplier * 0.0625;
	vec2 view = 1.0 / vec2(viewWidth, viewHeight);

	color *= multiplier * 0.25 + 1.0;

	for(int i = 0; i < 4; i++) {
		vec2 offset = sharpenOffsets[i] * view;
		color -= texture2D(colortex, coord + offset) * weight;
	}
}