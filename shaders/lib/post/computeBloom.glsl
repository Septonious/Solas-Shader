float pixelHeight = 0.8 / min(720.0, viewHeight);
float pixelWidth = pixelHeight / aspectRatio;
vec2 viewSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);

const float weight[6] = float[6](0.03, 0.15, 0.32, 0.32, 0.15, 0.03);

vec3 getBloomTile(float lod, vec2 bloomCoord, vec2 offset) {
	vec3 bloom = vec3(0.0);
	float scale = exp2(lod);
	bloomCoord = (bloomCoord - offset) * scale;
	vec2 padding = vec2(0.5) + 2.0 * viewSize * scale;

	if (abs(bloomCoord.x - 0.5) < padding.x && abs(bloomCoord.y - 0.5) < padding.y) {
		for(int i = 0; i < 6; i++) {
			for(int j = 0; j < 6; j++) {
				float wg = weight[i] * weight[j];
				vec2 pixelOffset = vec2((float(i) - 2.5) * pixelWidth, (float(j) - 2.5) * pixelHeight);
				vec2 sampleCoord = bloomCoord + pixelOffset * scale;
				bloom += texture2D(colortex0, sampleCoord).rgb * wg;
			}
		}
	}

	return bloom;
}

vec3 computeBloom(vec2 texCoord) {
	vec2 bloomCoord = texCoord * viewHeight * 0.8 / min(720.0, viewHeight);
	vec3 blur =  getBloomTile(1.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.0   , 0.0 ) + vec2( 0.5, 0.0) * viewSize);
	     blur += getBloomTile(2.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.50  , 0.0 ) + vec2( 4.0, 0.0) * viewSize);
	     blur += getBloomTile(3.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.50  , 0.25) + vec2( 4.0, 4.0) * viewSize);
	     blur += getBloomTile(4.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.625 , 0.25) + vec2( 8.0, 4.0) * viewSize);
		 blur += getBloomTile(5.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.6875, 0.25) + vec2(12.0, 4.0) * viewSize);
		 blur = pow(blur / 32.0, vec3(0.25));
		 blur = clamp(blur + (Bayer8(gl_FragCoord.xy) - 0.5) / 384.0, vec3(0.0), vec3(1.0));
    return blur;
}