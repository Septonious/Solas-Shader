float getLinearDepth(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

vec2 offsetDist(float x) {
	float n = fract(x * 8.0) * PI;

    return vec2(cos(n), sin(n)) * x;
}

float computeAmbientOcclusion(float linearDepth0, float dither) {
	float ao = 0.0;

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

	float currentStep = 0.25 * dither + 0.25;

	float fovScale = gbufferProjection[1][1] / 1.37;
	float distScale = max((far - near) * linearDepth0 + near, 5.0);
	float radiusMult = (0.75 / AO_RADIUS) * (far - near);
	vec2 aoScale = AO_RADIUS * vec2(1.0 / aspectRatio, 1.0) * fovScale / distScale;

	for (int i = 0; i < 4; i++) {
		vec2 pixelOffset = offsetDist(currentStep) * aoScale;
		float angle = 0.0, dist = 0.0;
		
		for (int i = 0; i < 2; i++){
			float sampleDepth = getLinearDepth(texture2D(depthtex0, texCoord + pixelOffset).r);
			float aoSample = (linearDepth0 - sampleDepth) * radiusMult;

			angle += clamp(0.5 - aoSample, 0.0, 1.0);
			dist += clamp(0.25 * aoSample - 1.0, 0.0, 1.0);
			pixelOffset *= -1.0;
		}
		
		ao += clamp(angle + dist, 0.0, 1.0);
		currentStep += 0.25;
	}

	return ao * 0.25;
}