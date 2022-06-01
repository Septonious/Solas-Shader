float GetWaterHeightMap(vec3 worldPos, vec2 offset) {
    vec2 wind = vec2(frameTimeCounter);

	worldPos.xz -= worldPos.y * 0.25;

	offset /= 256.0;
	float noiseA = texture2D(noisetex, (worldPos.xz - wind) / 512.0 + offset).g;
	float noiseB = texture2D(noisetex, (worldPos.xz + wind) / 128.0 + offset).g;
	
	float noise = mix(noiseA, noiseB, 0.5);

    return noise;
}

vec3 GetParallaxWaves(vec3 worldPos, vec3 viewVector) {
	vec3 parallaxPos = worldPos;
	
	for(int i = 0; i < 4; i++) {
		float height = -1.25 * GetWaterHeightMap(parallaxPos, vec2(0.0)) + 0.25;
		parallaxPos.xz += height * viewVector.xy / viewDistance;
	}
	return parallaxPos;
}

vec3 GetWaterNormal(vec3 worldPos, vec3 viewPos, vec3 viewVector, vec2 lightmap) {
	vec3 waterPos = GetParallaxWaves(worldPos + cameraPosition, viewVector);

	float normalOffset = 0.75;
	
	float fresnel = pow8(clamp(1.0 + dot(normalize(normal), normalize(viewPos)), 0.0, 1.0));
	float normalStrength = (1.0 - fresnel) * lightmap.y;

	float h1 = GetWaterHeightMap(waterPos, vec2( normalOffset, 0.0));
	float h2 = GetWaterHeightMap(waterPos, vec2(-normalOffset, 0.0));
	float h3 = GetWaterHeightMap(waterPos, vec2(0.0,  normalOffset));
	float h4 = GetWaterHeightMap(waterPos, vec2(0.0, -normalOffset));

	float xDelta = (h2 - h1) / normalOffset;
	float yDelta = (h4 - h3) / normalOffset;

	vec3 normalMap = vec3(xDelta, yDelta, 1.0 - (xDelta * xDelta + yDelta * yDelta));
	return normalMap * normalStrength + vec3(0.0, 0.0, 1.0 - normalStrength);
}