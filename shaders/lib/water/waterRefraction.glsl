float getWaterHeightMap(vec3 worldPos, vec2 offset) {
    float noise = 0.0;
    
    vec2 wind = vec2(frameTimeCounter) * 0.5 * WATER_NORMAL_SPEED;

	offset /= 256.0;
	worldPos.xz -= worldPos.y * 0.2;

	#if WATER_NORMALS == 1
	float noiseA = texture2D(shadowcolor1, (worldPos.xz - wind) / 256.0 + offset).g;
	float noiseB = texture2D(shadowcolor1, (worldPos.xz + wind) / 48.0 + offset).g;
	#elif WATER_NORMALS == 2
	float noiseA = texture2D(shadowcolor1, (worldPos.xz - wind) / 256.0 + offset).r;
	float noiseB = texture2D(shadowcolor1, (worldPos.xz + wind) / 96.0 + offset).r;
	noiseA *= noiseA; noiseB *= noiseB;
	#endif
	
	#if WATER_NORMALS > 0
	noise = mix(noiseA, noiseB, WATER_NORMAL_DETAIL);
	#endif

    return noise * WATER_NORMAL_BUMP;
}

vec2 getRefraction(vec3 waterPos, vec3 viewPos){
	float viewDistance = 1.0 - clamp(length(viewPos) * 0.01, 0.0, 1.0);

	if (viewDistance > 0.0) {
		float h1 = getWaterHeightMap(waterPos, vec2( WATER_NORMAL_OFFSET, 0.0));
		float h2 = getWaterHeightMap(waterPos, vec2(-WATER_NORMAL_OFFSET, 0.0));
		float h3 = getWaterHeightMap(waterPos, vec2(0.0,  WATER_NORMAL_OFFSET));
		float h4 = getWaterHeightMap(waterPos, vec2(0.0, -WATER_NORMAL_OFFSET));

		float xDelta = (h2 - h1) / WATER_NORMAL_OFFSET;
		float yDelta = (h4 - h3) / WATER_NORMAL_OFFSET;

		return clamp(texCoord + vec2(xDelta, yDelta) * WATER_REFRACTION_STRENGTH * 0.05 * viewDistance, 0.0, 1.0);
	}
	return texCoord;
}