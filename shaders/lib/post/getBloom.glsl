float pixelWidth = 1.0 / viewWidth;
float pixelHeight = 1.0 / viewHeight;

vec3 getBloomTile(float lod, vec2 coord, vec2 offset) {
	float scale = exp2(lod);

	float resScale = 1.25 * min(360.0, viewHeight) / viewHeight;
	vec2 centerOffset = vec2(0.125 * pixelWidth, 0.125 * pixelHeight);
	vec3 bloom = getDiskBlur4(colortex1, ((coord / scale + offset) * resScale + centerOffset), 1.0).rgb;

	return pow4(bloom) * 256.0;
}

vec3 getBloom(vec2 coord) {
	float z0 = texture2D(depthtex0, coord).r;

	if (z0 > 0.56) {
		vec3 blur1 = getBloomTile(1.0, coord, vec2(0.0, 0.0));
		vec3 blur2 = getBloomTile(2.0, coord, vec2(0.6, 0.0));
		vec3 blur3 = getBloomTile(3.0, coord, vec2(0.6, 0.3));
		vec3 blur4 = getBloomTile(4.0, coord, vec2(0.0, 0.6));
		
		#if BLOOM_RADIUS == 1
		vec3 blur = blur1;
		#elif BLOOM_RADIUS == 2
		vec3 blur = (blur1 * 1.18 + blur2) / 2.18;
		#elif BLOOM_RADIUS == 3
		vec3 blur = (blur1 * 1.57 + blur2 * 1.41 + blur3) / 3.98;
		#elif BLOOM_RADIUS == 4
		vec3 blur = (blur1 * 2.11 + blur2 * 1.97 + blur3 * 1.57 + blur4) / 6.65;
		#endif

		return blur * BLOOM_STRENGTH * 0.25;
	} else {
		return vec3(0.0);
	}
}