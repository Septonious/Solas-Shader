float getWaterHeightMap(vec3 worldPos, vec2 offset) {
    float noise = 0.0;
    
    vec2 wind = vec2(frameTimeCounter) * 0.5 * WATER_NORMAL_SPEED;

	#ifdef OVERWORLD
	wind *= 1.0 + rainStrength * 0.5;
	#endif

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

	#ifdef OVERWORLD
	noise *= 1.0 + rainStrength * 0.5;
	#endif

    return noise * WATER_NORMAL_BUMP;
}

vec3 getParallaxWaves(vec3 waterPos, vec3 viewVector) {
	vec3 parallaxPos = waterPos;
	
	for(int i = 0; i < 4; i++) {
		float height = -1.25 * getWaterHeightMap(parallaxPos, vec2(0.0)) + 0.25;
		parallaxPos.xz += height * viewVector.xy / viewDistance;
	}

	return parallaxPos;
}

void getWaterNormal(inout vec3 newNormal, vec3 worldPos, vec3 viewVector, vec2 lightmap, float fresnel) {
	vec3 waterPos = getParallaxWaves(worldPos + cameraPosition, viewVector);

	float harmonic0 = getWaterHeightMap(waterPos, vec2( WATER_NORMAL_OFFSET, 0.0));
	float harmonic1 = getWaterHeightMap(waterPos, vec2(-WATER_NORMAL_OFFSET, 0.0));
	float harmonic2 = getWaterHeightMap(waterPos, vec2(0.0,  WATER_NORMAL_OFFSET));
	float harmonic3 = getWaterHeightMap(waterPos, vec2(0.0, -WATER_NORMAL_OFFSET));

	float xDelta = (harmonic1 - harmonic0) / WATER_NORMAL_OFFSET;
	float yDelta = (harmonic3 - harmonic2) / WATER_NORMAL_OFFSET;

	vec3 normalMap = vec3(xDelta, yDelta, 1.0 - (xDelta * xDelta + yDelta * yDelta));
		 normalMap = normalMap * lightmap.y + vec3(0.0, 0.0, -fresnel * 0.5);

	if (normalMap.xz != vec2(0.0)) {
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							  tangent.y, binormal.y, normal.y,
							  tangent.z, binormal.z, normal.z);

		newNormal = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
	}
}