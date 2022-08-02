const vec2 aoOffsets[4] = vec2[4](
	vec2( 1.0,  0.0),
	vec2( 0.0,  1.0),
	vec2(-1.0,  0.0),
	vec2( 0.0, -1.0)
);

float getLinearDepth(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

float getAmbientOcclusion(float z){
	float ao = 0.0;
	float totalWeight = 0.0;
	float depth0 = getLinearDepth(z);
	
	for(int i = 0; i < 4; i++){
		vec2 offset = aoOffsets[i] / vec2(viewWidth, viewHeight);
		float sampleDepth = getLinearDepth(texture2D(depthtex0, texCoord + offset * 2.0).r);
		float weight = max(1.0 - 2.0 * far * abs(depth0 - sampleDepth), 0.00001);
		ao += texture2DLod(colortex4, texCoord + offset * 2.0, 1).r * weight;
		totalWeight += weight;
	}
	ao /= totalWeight;
	if (totalWeight < 0.0001) ao = texture2D(colortex4, texCoord).r;

	return pow(ao, AO_STRENGTH);
}