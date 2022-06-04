float pixelHeight = 0.8 / min(360.0, viewHeight);
float pixelWidth = pixelHeight / aspectRatio;

const vec2 bloomOffsets[8] = vec2[8](
   vec2(0.2921473492144121, 0.03798942536906266),
   vec2(-0.27714274097351554, 0.3304853027892154),
   vec2(0.09101981507673855, -0.5188871157785563),
   vec2(0.44459182774878003, 0.5629069824170247),
   vec2(-0.6963877647721594, -0.09264703741542105),
   vec2(0.7417522811565185, -0.4070419658858473),
   vec2(-0.191856808948964, 0.9084732299066597),
   vec2(-0.40412395850181015, -0.8212788214021378)
);

vec3 getBloomTile(float lod, vec2 coord, vec2 offset) {
	vec3 bloom = vec3(0.0), temp = vec3(0.0);
	float scale = exp2(lod);
	coord = (coord - offset) * scale;
	float padding = 0.5 + 0.005 * scale;

	if (abs(coord.x - 0.5) < padding && abs(coord.y - 0.5) < padding) {
		for (int i = 0; i < 8; i++) {
			vec2 pixelOffset = bloomOffsets[i] * vec2(pixelWidth, pixelHeight);
			bloom += texture2D(colortex0, coord + pixelOffset * scale).rgb;
		}
		bloom *= 0.125;
	}

	return bloom;
}

vec3 getBlur(vec2 texCoord) {
	vec2 bloomCoord = texCoord * viewHeight * 0.8 / min(360.0, viewHeight);
	vec3 blur =  getBloomTile(1.0, bloomCoord, vec2(0.0   , 0.0   ));
	     blur += getBloomTile(2.0, bloomCoord, vec2(0.51  , 0.0   ));
	     blur += getBloomTile(3.0, bloomCoord, vec2(0.51  , 0.26  ));
	     blur += getBloomTile(4.0, bloomCoord, vec2(0.645 , 0.26  ));
	     blur += getBloomTile(5.0, bloomCoord, vec2(0.7175, 0.26  ));
		
		 blur = clamp(blur, vec3(0.0), vec3(1.0));

    return blur;
}