float pixelHeight = 0.8 / min(360.0, viewHeight);
float pixelWidth = pixelHeight / aspectRatio;

const float weight[6] = float[6](0.0556, 0.1667, 0.2777, 0.2777, 0.1667, 0.0556);

vec3 getBloomTile(float lod, vec2 coord, vec2 offset) {
	vec3 bloom = vec3(0.0);
	float scale = exp2(lod);
	coord = (coord - offset) * scale;
	float padding = 0.5 + 0.005 * scale;

	if (abs(coord.x - 0.5) < padding && abs(coord.y - 0.5) < padding) {
		for(int i = 0; i < 6; i++) {
			for(int j = 0; j < 6; j++) {
				vec2 pixelOffset = vec2((i - 2.5) * pixelWidth, (j - 2.5) * pixelHeight);
				vec2 sampleCoord = coord + pixelOffset * scale;
				
				float isEmissive = texture2D(colortex2, sampleCoord).b;

				if (isEmissive > 0.0) bloom += texture2D(colortex0, sampleCoord).rgb * weight[i] * weight[j] * isEmissive;
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