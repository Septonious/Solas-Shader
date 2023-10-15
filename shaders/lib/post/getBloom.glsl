float pixelWidth = 1.0 / viewWidth;
float pixelHeight = 1.0 / viewHeight;

vec3 getBloomTile(float lod, vec2 bloomCoord, vec2 offset, vec2 dither) {
	float scale = exp2(lod);

	float resScale = 1.25 * min(360.0, viewHeight) / viewHeight;
	vec3 bloom = texture2DLod(colortex1, (bloomCoord / scale + offset) * resScale + dither, 0.0).rgb;

	return pow4(bloom) * 128.0;
}

vec3 getBloom(vec2 bloomCoord, float dither, float z0) {
	vec3 blur = vec3(0.0);

	if (z0 > 0.56) {
		vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);

		vec2 dithervec2 = vec2(0.0);
		dithervec2.x += (dither - 0.5) * pixelWidth;
		dithervec2.y += (dither - 0.5) * pixelHeight;

		vec3 blur1 = getBloomTile(1.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.0   , 0.0 ), dithervec2);
		vec3 blur2 = getBloomTile(2.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.51  , 0.0 ), dithervec2);
		vec3 blur3 = getBloomTile(3.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.51  , 0.26), dithervec2);
		vec3 blur4 = getBloomTile(4.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.645 , 0.26), dithervec2);
		vec3 blur5 = getBloomTile(5.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.7175, 0.26), dithervec2);
		blur = (blur1 * 2.89 + blur2 * 2.74 + blur3 * 2.30 + blur4 * 1.68 + blur5) / 10.61;
	}

	return blur;
}