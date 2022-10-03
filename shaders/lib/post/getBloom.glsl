float pixelWidth = 1.0 / viewWidth;
float pixelHeight = 1.0 / viewHeight;

vec3 getBloomTile(float lod, vec2 coord, vec2 offset, vec2 bloomDither) {
	float scale = exp2(lod);
	float resScale = 1.25 * min(360.0, viewHeight) / viewHeight;
	
	vec2 centerOffset = vec2(0.125 * pixelWidth, 0.25 * pixelHeight);
	vec3 bloom = getDiskBlur16(colortex1, (coord / scale + offset) * resScale + centerOffset + bloomDither, 4.0).rgb;

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

		vec3 blur =  getBloomTile(1.0, bloomCoord, vec2(0.0000, 0.0000), bloomDither);
			 blur += getBloomTile(2.0, bloomCoord, vec2(0.5100, 0.0000), bloomDither);
			 blur += getBloomTile(3.0, bloomCoord, vec2(0.5100, 0.2600), bloomDither);
			 blur += getBloomTile(4.0, bloomCoord, vec2(0.6450, 0.2600), bloomDither);
			 blur += getBloomTile(5.0, bloomCoord, vec2(0.7175, 0.2600), bloomDither);

		return blur * (BLOOM_STRENGTH + 2.0);
	} else {
		return vec3(0.0);
	}
}