vec2 pixelSize = 1.0 / vec2(viewWidth, viewHeight);

vec2 blurOffsets[8] = vec2[8](
   vec2(0.2921473492144121, 0.03798942536906266),
   vec2(-0.27714274097351554, 0.3304853027892154),
   vec2(0.09101981507673855, -0.5188871157785563),
   vec2(0.44459182774878003, 0.5629069824170247),
   vec2(-0.6963877647721594, -0.09264703741542105),
   vec2(0.7417522811565185, -0.4070419658858473),
   vec2(-0.191856808948964, 0.9084732299066597),
   vec2(-0.40412395850181015, -0.8212788214021378)
);

vec4 getDiskBlur(sampler2D colortex, vec2 coord, float strength) {
	vec4 blur = vec4(0.0);

	for(int i = 0; i < 8; i++) {
		vec2 pixelOffset = blurOffsets[i] * pixelSize * strength;
		blur += texture2D(colortex, coord + pixelOffset);
	}

	blur *= 0.125;

	return blur;
}