float getWaterHeightMap(vec3 waterPos, vec2 offset) {
	waterPos.xz -= waterPos.y * 0.25;

	offset /= 256.0;
	#ifdef BLOCKY_CLOUDS
	float noiseA = texture2D(noisetex, (waterPos.xz - frameTimeCounter * 0.8) / 384.0 + offset).r;
	float noiseB = texture2D(noisetex, (waterPos.xz + frameTimeCounter) / 256.0 + offset).r;
	#else
	float noiseA = texture2D(shadowcolor1, (waterPos.xz - frameTimeCounter * 0.8) / 256.0 + offset).r;
	float noiseB = texture2D(shadowcolor1, (waterPos.xz + frameTimeCounter) / 96.0 + offset).r;
	#endif

	return mix(noiseA, noiseB, 0.5) * WATER_NORMAL_BUMP;
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
	} return texCoord;
}