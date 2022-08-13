float pixelHeight = 0.8 / min(360.0, viewHeight);
float pixelWidth = pixelHeight / aspectRatio;

float gaussian2D(vec2 offset) {
    return 0.5 * exp(-dot(offset, offset) * 0.5);
}

vec3 getBloomTile(float lod, vec2 coord, vec2 offset) {
	vec3 bloom = vec3(0.0);
	float scale = exp2(lod);
	coord = (coord - offset) * scale;
	float padding = 0.5 + 0.005 * scale;

	if (abs(coord.x - 0.5) < padding && abs(coord.y - 0.5) < padding) {
		for(int i = -BLOOM_SAMPLES; i <= BLOOM_SAMPLES; i++) {
			for(int j = -BLOOM_SAMPLES; j <= BLOOM_SAMPLES; j++) {
				vec2 pixelOffset = vec2(i * pixelWidth, j * pixelHeight);
				vec2 sampleCoord = coord + pixelOffset * scale;
				float isEmissive = texture2D(colortex2, sampleCoord).b * 100.0;

				if (isEmissive > 0.0) bloom += texture2D(colortex0, sampleCoord).rgb * gaussian2D(vec2(i, j)) * isEmissive;
			}
		}
	}

	return pow(bloom / 256.0, vec3(0.25));
}

vec3 getBlur(vec2 texCoord) {
	vec2 bloomCoord = texCoord * viewHeight * 0.8 / min(360.0, viewHeight);
	vec3 blur =  getBloomTile(1.0, bloomCoord, vec2(0.0, 0.0));
	     blur += getBloomTile(2.0, bloomCoord, vec2(0.6, 0.0));
	     blur += getBloomTile(3.0, bloomCoord, vec2(0.6, 0.3));
	     blur += getBloomTile(4.0, bloomCoord, vec2(0.0, 0.6));
		
		 blur = clamp(blur, vec3(0.0), vec3(1.0));

    return blur;
}