float pixelWidth = 1.0 / viewWidth;
float pixelHeight = 1.0 / viewHeight;

vec3 getBloomTile(float lod, vec2 bloomCoord, vec2 offset, vec2 bloomDither) {
	const float resScale = 1.25;
	float scale = exp2(lod);
	
	vec2 centerOffset = vec2(0.125 * pixelWidth, 0.25 * pixelHeight);
	vec3 bloom = getDiskBlur4(colortex1, (bloomCoord / scale + offset) * resScale + centerOffset + bloomDither, 1.0).rgb;

	return pow8(bloom) * 512.0;
}

vec3 getBloom(vec2 bloomCoord, float dither) {
	float z0 = texture2D(depthtex0, bloomCoord).r;

	if (z0 > 0.56) {
		vec2 viewScale = 1.0 / vec2(viewWidth, viewHeight);
		vec2 bloomDither = vec2(0.0);

		#ifdef TAA
		dither = fract(dither + frameTimeCounter * 16.0);
		#endif

		bloomDither = vec2(dither * pixelWidth, dither * pixelHeight);

		vec3 blur1 = getBloomTile(1.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.0   , 0.0 ), bloomDither);
		vec3 blur2 = getBloomTile(2.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.51  , 0.0 ), bloomDither);
		vec3 blur3 = getBloomTile(3.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.51  , 0.26), bloomDither);
		vec3 blur4 = getBloomTile(4.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.645 , 0.26), bloomDither);
		vec3 blur5 = getBloomTile(5.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.7175, 0.26), bloomDither);

		#if BLOOM_RADIUS == 1
		vec3 blur = blur1;
		#elif BLOOM_RADIUS == 2
		vec3 blur = (blur1 * 1.18 + blur2) / 2.18;
		#elif BLOOM_RADIUS == 3
		vec3 blur = (blur1 * 1.57 + blur2 * 1.41 + blur3) / 3.98;
		#elif BLOOM_RADIUS == 4
		vec3 blur = (blur1 * 2.11 + blur2 * 1.97 + blur3 * 1.57 + blur4) / 6.65;
		#elif BLOOM_RADIUS == 5
		vec3 blur = (blur1 * 2.89 + blur2 * 2.74 + blur3 * 2.30 + blur4 * 1.68 + blur5) / 10.61;
		#endif

		return blur;
	} else {
		return vec3(0.0);
	}
}