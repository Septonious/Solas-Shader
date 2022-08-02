float getLinearDepth(float depth0) {
   return (2.0 * near) / (far + near - depth0 * (far - near));
}

vec2 offsetDist(float x) {
	float n = fract(x * 8.0) * 3.1415;
    return vec2(cos(n), sin(n)) * x;
}

float calculateAmbientOcclusion(float dither) {
	float ao = 0.0;
	
	float depth0 = texture2D(depthtex0, texCoord).r;
	if (depth0 >= 1.0) return 1.0;

	float hand = float(depth0 < 0.56);
	depth0 = getLinearDepth(depth0);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

	float currentStep = 0.4 * dither + 0.2;

	float angle = 0.0, dist = 0.0;
	float fovScale = gbufferProjection[1][1] / 1.37;
	float distScale = max((far - near) * depth0 + near, 5.0);
	vec2 scale = AO_RADIUS * vec2(1.0 / aspectRatio, 1.0) * fovScale / distScale;
	float mult = (0.7 / AO_RADIUS) * (far - near) * (hand > 0.5 ? 1024.0 : 1.0);

	for(int i = 0; i < 4; i++) {
		vec2 offset = offsetDist(currentStep) * scale;

		for(int i = 0; i < 2; i++){
			float sampleDepth = getLinearDepth(texture2D(depthtex0, texCoord + offset).r);
			float sample = (depth0 - sampleDepth) * mult;
			angle += clamp(0.5 - sample, 0.0, 1.0);
			dist += clamp(0.25 * sample - 1.0, 0.0, 1.0);
			offset = -offset;
		}
		
		ao += clamp(angle + dist, 0.0, 1.0);
		currentStep += 0.2;
	}
	ao *= 0.25;
	
	return ao;
}