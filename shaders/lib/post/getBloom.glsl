vec3 getBloomTile(float lod, vec2 bloomCoord, vec2 offset) {
	float scale = exp2(lod);
	float resScale = 1.25 * min(720.0, viewHeight) / viewHeight;
	vec3 bloom = texture2D(colortex1, (bloomCoord / scale + offset) * resScale).rgb;
	bloom *= bloom; bloom *= bloom * 32.0;
	return bloom;
}

void getBloom(inout vec3 color, vec2 bloomCoord, in float z1) {
	vec2 viewSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);
	vec3 blur1 = getBloomTile(1.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.0   , 0.0 ) + vec2( 0.5, 0.0) * viewSize);
	vec3 blur2 = getBloomTile(2.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.50  , 0.0 ) + vec2( 4.5, 0.0) * viewSize);
	vec3 blur3 = getBloomTile(3.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.50  , 0.25) + vec2( 4.5, 4.0) * viewSize);
	vec3 blur4 = getBloomTile(4.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.625 , 0.25) + vec2( 8.5, 4.0) * viewSize);
	vec3 blur5 = getBloomTile(5.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.6875, 0.25) + vec2(12.5, 4.0) * viewSize);

	vec3 blur = (blur1 * 3.58 + blur2 * 3.35 + blur3 * 2.72 + blur4 * 1.87 + blur5) / 12.52;

    #if defined OVERWORLD
    float bloomStrength = BLOOM_STRENGTH_OVERWORLD * (1.0 + float(z1 == 1.0) * moonVisibility);
		  bloomStrength += float(isEyeInWater == 1);
    #elif defined NETHER
    float bloomStrength = BLOOM_STRENGTH_NETHER;
    #elif defined END
    float bloomStrength = BLOOM_STRENGTH_END;
    #endif

	#if BLOOM_CONTRAST == 0
	color = mix(color, blur, 0.25 * bloomStrength);
	#else
	vec3 bloomContrast = vec3(exp2(BLOOM_CONTRAST * 0.25));
	color = pow(color, bloomContrast);
	blur = pow(blur, bloomContrast);
	vec3 strengthFactor = pow(vec3(0.2 * bloomStrength), bloomContrast);
	color = mix(color, blur, strengthFactor);
	color = pow(color, 1.0 / bloomContrast);
	#endif
}