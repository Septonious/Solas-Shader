float pixelWidth = 1.0 / viewWidth;
float pixelHeight = 1.0 / viewHeight;

vec3 getBloomTile(float lod, vec2 bloomCoord, vec2 offset) {
	float scale = exp2(lod);

	float resScale = 1.25 * min(360.0, viewHeight) / viewHeight;
	vec3 bloom = texture2DLod(colortex1, (bloomCoord / scale + offset) * resScale, 0.0).rgb;

	return pow4(bloom) * 128.0;
}

void getBloom(inout vec3 color, vec2 coord, float z1) {
	float eBS = eyeBrightnessSmooth.y / 240.0;
	vec2 viewSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);
	vec3 blur1 = getBloomTile(1.0 + BLOOM_TILE_SIZE, coord, vec2(0.0   , 0.0 ) + vec2( 0.5, 0.0) * viewSize);
	vec3 blur2 = getBloomTile(2.0 + BLOOM_TILE_SIZE, coord, vec2(0.50  , 0.0 ) + vec2( 4.5, 0.0) * viewSize);
	vec3 blur3 = getBloomTile(3.0 + BLOOM_TILE_SIZE, coord, vec2(0.50  , 0.25) + vec2( 4.5, 4.0) * viewSize);
	vec3 blur4 = getBloomTile(4.0 + BLOOM_TILE_SIZE, coord, vec2(0.625 , 0.25) + vec2( 8.5, 4.0) * viewSize);

	vec3 blur = (blur1 * 2.46 + blur2 * 2.25 + blur3 * 1.71 + blur4) / 7.42;
	
	#if BLOOM_CONTRAST == 0
	color = mix(color, blur, 0.25 * BLOOM_STRENGTH);
	#else
	vec3 bloomContrast = vec3(exp2(BLOOM_CONTRAST * 0.25));
	color = pow(color, bloomContrast);
	blur = pow(blur, bloomContrast);
	vec3 bloomStrength = pow(vec3(0.2 * BLOOM_STRENGTH), bloomContrast) * (2.0 - eBS);
	color = mix(color, blur, bloomStrength);
	color = pow(color, 1.0 / bloomContrast);
	#endif
}