float getWaterHeightMap(vec3 worldPos, vec2 offset) {
	worldPos.xz -= worldPos.y * 0.25;

	offset /= 256.0;
	offset *= WATER_NORMAL_VISIBILITY;
	float noiseA = texture2D(noisetex, (worldPos.xz - frameTimeCounter * 0.50) / 512.0 + offset).g;
	float noiseB = texture2D(noisetex, (worldPos.xz + frameTimeCounter * 0.75) / 128.0 + offset).g;

    return mix(noiseA * noiseA, noiseB * noiseB, 0.25) * WATER_NORMAL_BUMP;
}

vec3 getParallaxWaves(vec3 worldPos, vec3 viewVector) {
	vec3 parallaxPos = worldPos;
	
	for(int i = 0; i < 4; i++) {
		float height = -1.25 * getWaterHeightMap(parallaxPos, vec2(0.0)) + 0.25;
		parallaxPos.xz += height * viewVector.xy / viewDistance;
	}

	return parallaxPos;
}

vec3 getWaterNormal(vec3 worldPos, vec3 viewPos, vec3 viewVector, vec2 lightmap) {
	vec3 waterPos = getParallaxWaves(worldPos + cameraPosition, viewVector);
	
	float fresnel = pow4(clamp(1.0 + dot(normalize(normal), normalize(viewPos)), 0.0, 1.0));
	float normalStrength = (1.0 - fresnel) * lightmap.y;

	float harmonic0 = getWaterHeightMap(waterPos, vec2( WATER_NORMAL_OFFSET, 0.0));
	float harmonic1 = getWaterHeightMap(waterPos, vec2(-WATER_NORMAL_OFFSET, 0.0));
	float harmonic2 = getWaterHeightMap(waterPos, vec2(0.0,  WATER_NORMAL_OFFSET));
	float harmonic3 = getWaterHeightMap(waterPos, vec2(0.0, -WATER_NORMAL_OFFSET));

	float xDelta = (harmonic1 - harmonic0) / WATER_NORMAL_OFFSET;
	float yDelta = (harmonic3 - harmonic2) / WATER_NORMAL_OFFSET;

	vec3 normalMap = vec3(xDelta, yDelta, 1.0 - (xDelta * xDelta + yDelta * yDelta));

	return normalMap * normalStrength + vec3(0.0, 0.0, 1.0 - normalStrength);
}