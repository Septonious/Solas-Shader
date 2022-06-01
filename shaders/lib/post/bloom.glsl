float pixelHeight = 0.8 / min(360.0, viewHeight);
float pixelWidth = pixelHeight / aspectRatio;

float weight[5] = float[5](1.0, 4.0, 6.0, 4.0, 1.0);

vec3 BloomTile(float lod, vec2 coord, vec2 offset) {
	vec3 bloom = vec3(0.0), temp = vec3(0.0);
	float scale = exp2(lod);
	coord = (coord - offset) * scale;
	float padding = 0.5 + 0.005 * scale;

	if (abs(coord.x - 0.5) < padding && abs(coord.y - 0.5) < padding) {
		for(int i = 0; i < 5; i++) {
			for(int j = 0; j < 5; j++) {
				float wg = weight[i] * weight[j];

				vec2 pixelOffset = vec2((float(i) - 2.0) * pixelWidth, (float(j) - 2.0) * pixelHeight);
				vec2 sampleCoord = coord + pixelOffset * scale;
				bloom += texture(colortex0, sampleCoord).rgb * wg;
			}
		}
		bloom *= 0.01;
	}

	return bloom;
}

vec3 getBlur(vec2 texCoord) {
	vec2 bloomCoord = texCoord * viewHeight * 0.8 / min(360.0, viewHeight);
	vec3 blur =  BloomTile(1.0, bloomCoord,vec2(0.0   , 0.0   ));
	     blur += BloomTile(2.0, bloomCoord,vec2(0.51  , 0.0   ));
	     blur += BloomTile(3.0, bloomCoord,vec2(0.51  , 0.26  ));
	     blur += BloomTile(4.0, bloomCoord,vec2(0.645 , 0.26  ));
	     blur += BloomTile(5.0, bloomCoord,vec2(0.7175, 0.26  ));
	     blur += BloomTile(6.0, bloomCoord,vec2(0.645 , 0.3325));
		
		 blur = clamp(blur, vec3(0.0), vec3(1.0));

    return blur;
}