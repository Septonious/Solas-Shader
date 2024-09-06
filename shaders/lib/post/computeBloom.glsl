float pixelHeight = 0.8 / min(360.0, viewHeight);
float pixelWidth = pixelHeight / aspectRatio;
vec2 viewSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);

const float weight[6] = float[6](0.0556, 0.1667, 0.2777, 0.2777, 0.1667, 0.0556);

vec3 getBloomTile(float lod, vec2 bloomCoord, vec2 offset) {
	vec3 bloom = vec3(0.0);

	float scale = exp2(lod);
	bloomCoord = (bloomCoord - offset) * scale;
	vec2 padding = vec2(0.5) + 2.0 * viewSize * scale;

	if (abs(bloomCoord.x - 0.5) < padding.x && abs(bloomCoord.y - 0.5) < padding.y) {
		for(int i = 0; i < 6; i++) {
			for(int j = 0; j < 6; j++) {
				vec2 pixelOffset = vec2((i - 2.25) * pixelWidth, (j - 2.25) * pixelHeight);
				vec2 sampleCoord = bloomCoord + pixelOffset * scale;

				bloom += clamp(texture2D(colortex0, sampleCoord).rgb, 0.0, 1.0) * weight[i] * weight[j];
			}
		}
	}

	return pow(bloom / 256.0, vec3(0.125));
}

vec3 computeBloom(vec2 texCoord) {
	vec2 bloomCoord = texCoord * viewHeight * 0.8 / min(360.0, viewHeight);
	vec3 blur =  getBloomTile(1.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.0   , 0.0 ) + vec2( 0.5, 0.0) * viewSize);
	     blur += getBloomTile(2.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.50  , 0.0 ) + vec2( 4.0, 0.0) * viewSize);
	     blur += getBloomTile(3.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.50  , 0.25) + vec2( 4.0, 4.0) * viewSize);
	     blur += getBloomTile(4.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.625 , 0.25) + vec2( 8.0, 4.0) * viewSize);

    return clamp(blur, 0.0, 1.0);
}