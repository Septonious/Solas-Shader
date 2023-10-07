const vec2 aoOffsets[4] = vec2[4](
	vec2( 1.0,  0.0),
	vec2( 0.0,  1.0),
	vec2(-1.0,  0.0),
	vec2( 0.0, -1.0)
);

float getLinearDepth(in float depth) {
    return 1.0 / ((depth * 2.0 - 1.0) * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);
}

float getAmbientOcclusion(float linearDepth0){
	float ao = 0.0;
	float totalWeight = 0.0;
	
	for (int i = 0; i < 4; i++){
		vec2 pixelOffset = aoOffsets[i] / vec2(viewWidth, viewHeight);
		float sampleDepth = getLinearDepth(texture2D(depthtex0, texCoord + pixelOffset).r);
		float weight = max(1.0 - 2.0 * far * abs(linearDepth0 - sampleDepth), 0.0001);

		ao += texture2D(colortex4, texCoord + pixelOffset).a * weight;
		totalWeight += weight;
	}

	ao /= totalWeight;
	
	if (totalWeight < 0.0001) ao = texture2D(colortex4, texCoord).a;

	return pow(ao, AO_STRENGTH);
}