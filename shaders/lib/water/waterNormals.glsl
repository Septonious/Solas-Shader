float getWaterHeightMap(vec3 worldPos, vec2 offset) {
    float noise = 0.0;
    
    vec2 wind = vec2(frameTimeCounter) * 0.5 * WATER_NORMAL_SPEED;

	offset /= 256.0;
	worldPos.xz -= worldPos.y * 0.2;

	#if WATER_NORMALS == 1
	float noiseA = texture2D(noisetex, (worldPos.xz - wind) / 512.0 + offset).r * 4;
	float noiseB = texture2D(noisetex, (worldPos.xz + wind) / 64.0 + offset).g;
	#elif WATER_NORMALS == 2
	float noiseA = texture2D(noisetex, (worldPos.xz - wind) / 256.0 + offset).r;
	float noiseB = texture2D(noisetex, (worldPos.xz + wind) / 96.0 + offset).r;
	noiseA *= noiseA;
    noiseB *= noiseB;
	#endif
	
	#if WATER_NORMALS > 0
	noise = mix(noiseA, noiseB, WATER_NORMAL_DETAIL);
	#endif

	#ifdef OVERWORLD
    return noise * (WATER_NORMAL_BUMP + wetness * 0.5);
	#else
	return noise * WATER_NORMAL_BUMP;
	#endif
}

vec3 getParallaxWaves(vec3 waterPos) {
	vec3 parallaxPos = waterPos;
	
	for(int i = 0; i < 4; i++) {
		float height = -1.25 * getWaterHeightMap(parallaxPos, vec2(0.0)) + 0.25;
		parallaxPos.xz += height * viewVector.xy / viewDistance;
	}

	return parallaxPos;
}

void getWaterNormal(inout vec3 newNormal, vec3 worldPos, in float fresnel) {
	vec3 waterPos = getParallaxWaves(worldPos + cameraPosition);

	float h0 = getWaterHeightMap(waterPos, vec2( WATER_NORMAL_OFFSET, 0.0));
	float h1 = getWaterHeightMap(waterPos, vec2(-WATER_NORMAL_OFFSET, 0.0));
	float h2 = getWaterHeightMap(waterPos, vec2(0.0,  WATER_NORMAL_OFFSET));
	float h3 = getWaterHeightMap(waterPos, vec2(0.0, -WATER_NORMAL_OFFSET));

	float xDelta = (h1 - h0) / WATER_NORMAL_OFFSET;
	float yDelta = (h3 - h2) / WATER_NORMAL_OFFSET;

	vec3 normalMap = vec3(xDelta, yDelta, 1.0 - (xDelta * xDelta + yDelta * yDelta));

	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							tangent.y, binormal.y, normal.y,
							tangent.z, binormal.z, normal.z);

	float normalStrength = 0.35 * (1.0 - pow8(fresnel));

	newNormal = normalMap * normalStrength + vec3(0.0, 0.0, 1.0 - normalStrength);
	newNormal = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
}