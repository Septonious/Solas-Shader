float getLinearDepth(in float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

#ifdef DISTANT_HORIZONS
float GetDHLinearDepth(float depth) {
   return (2.0 * dhNearPlane) / (dhFarPlane + dhNearPlane - depth * (dhFarPlane - dhNearPlane));
}
#endif

vec2 offsetDist(float x) {
	float n = fract(x * 8.0) * PI;

    return vec2(cos(n), sin(n)) * x;
}

float computeAmbientOcclusion(float dither) {
	float ao = 0.0;
	
	float depth = texture2D(depthtex0, texCoord).r;
	if(depth >= 1.0) return 1.0;

	float hand = float(depth < 0.56);
	depth = getLinearDepth(depth);

	float currentStep = 0.198 * dither + 0.01;

	float radius = AO_RADIUS;
	float fovScale = gbufferProjection[1][1] / 1.37;
	float distScale = max((far - near) * depth + near, 5.0);
	vec2 scale = radius * vec2(1.0 / aspectRatio, 1.0) * fovScale / distScale;
	float mult = (0.7 / radius) * (far - near) * (hand > 0.5 ? 1024.0 : 1.0);

	for(int i = 0; i < 5; i++) {
		vec2 offset = offsetDist(currentStep) * scale;
		float angle = 0.0, dist = 0.0;

		for(int i = 0; i < 2; i++){
			float sampleDepth = getLinearDepth(texture2D(depthtex0, texCoord + offset).r);
			float aoSample = (depth - sampleDepth) * mult / currentStep;
			angle += clamp(0.5 - aoSample, 0.0, 1.0);
			dist += clamp(0.25 * aoSample - 1.0, 0.0, 1.0);
			offset = -offset;
		}
		
		ao += clamp(angle + dist, 0.0, 1.0);
		currentStep += 0.198;
	}
	ao *= 0.2;
	
	return ao;
}

#ifdef DISTANT_HORIZONS
float computeAmbientOcclusionDH(float dither) {
	float ao = 0.0;
	
	float depth = texture2D(dhDepthTex0, texCoord).r;
	if(depth >= 1.0) return 1.0;

	depth = GetDHLinearDepth(depth);

	float currentStep = 0.198 * dither + 0.01;

	float radius = 4.0;
	float fovScale = gbufferProjection[1][1] / 1.37;
	float distScale = max((dhFarPlane - dhNearPlane) * depth + dhNearPlane, 5.0);
	vec2 scale = radius * vec2(1.0 / aspectRatio, 1.0) * fovScale / distScale;
	float mult = (0.7 / radius) * (dhFarPlane - dhNearPlane);

	for(int i = 0; i < 5; i++) {
		vec2 offset = offsetDist(currentStep) * scale;
		float angle = 0.0, dist = 0.0;

		for(int i = 0; i < 2; i++){
			float sampleDepth = GetDHLinearDepth(texture2D(dhDepthTex0, texCoord + offset).r);
			float aoSample = (depth - sampleDepth) * mult / currentStep;
			angle += clamp(0.5 - aoSample, 0.0, 1.0);
			dist += clamp(0.25 * aoSample - 1.0, 0.0, 1.0);
			offset = -offset;
		}
		
		ao += clamp(angle + dist, 0.0, 1.0);
		currentStep += 0.198;
	}
	ao *= 0.2;
	
	return ao;
}
#endif