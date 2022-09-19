vec3 ToVec3(vec4 reflectionPos) {
    return reflectionPos.xyz / reflectionPos.w;
}

float getCoordDistance(vec2 coord) {
	return max(abs(coord.x - 0.5), abs(coord.y - 0.5)) * 1.85;
}

vec3 rayTrace(vec3 viewPos, vec3 normal, float dither, out float border, int refinementSteps, float stepSize, float refinementMult, float refinementFactor) {
	vec3 reflectionPos = vec3(0.0);
	int totalRefinementSteps = 0;
	float rayDistance = 0.0;
	
	#ifdef TAA
	dither = fract(dither + frameTimeCounter);
	#endif

	vec3 startPos = viewPos + normal * 0.035;

    vec3 rayDir = stepSize * reflect(normalize(viewPos), normalize(normal));
    viewPos += rayDir;

	vec3 rayIncrement = rayDir;

    for (int i = 0; i < REFLECTION_RT_SAMPLE_COUNT; i++) {
        reflectionPos = ToVec3(gbufferProjection * vec4(viewPos, 1.0)) * 0.5 + 0.5;

		if (reflectionPos.x < -0.05 || reflectionPos.x > 1.05 || reflectionPos.y < -0.05 || reflectionPos.y > 1.05) break;

		vec3 rayPos = vec3(reflectionPos.xy, texture2D(depthtex1, reflectionPos.xy).r);
        rayPos = ToVec3(gbufferProjectionInverse * vec4(rayPos * 2.0 - 1.0, 1.0));
		rayDistance = abs(dot(startPos - rayPos, normal));

        float err = length(viewPos - rayPos);
		float rayLength = length(rayDir) * pow(length(rayIncrement), 0.1) * 1.3;

		if (err < rayLength) {
			totalRefinementSteps++;
			if (totalRefinementSteps >= refinementSteps) break;

			rayIncrement -= rayDir;
			rayDir *= refinementMult;
		}

        rayDir *= refinementFactor;
        rayIncrement += rayDir;
		viewPos = startPos + rayIncrement * (0.025 * dither + 0.975);
    }

	border = getCoordDistance(reflectionPos.xy);

	return reflectionPos;
}