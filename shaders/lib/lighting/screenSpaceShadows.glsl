vec3 computeScreenSpaceShadows(vec3 viewPos, vec3 lightVector, sampler2D depthtex, mat4 projection, mat4 projectionInverse,  float dither) {
	float shadow = 1.0;
	float shadowMask = texture2D(colortex3, texCoord).r;

	float traceZ = 0.0;
	float zDelta = 0.0;
	float thickness = 4.0;

	for (int i = 0; i < 16; i++) {
		float traceStep = exp2((i + dither) * 0.5 - 2.0);
		vec3 tracePos = viewPos + lightVector * traceStep;

		vec4 pos = projection * vec4(tracePos, 1.0);
                pos = pos / pos.w * 0.5 + 0.5;

		if (pos.x < 0.0 || pos.x > 1.0 || pos.y < 0.0 || pos.y > 1.0) break;

		#ifdef VOXY
		traceZ = texture2D(depthtex0, pos.xy).r;
		zDelta = -tracePos.z - GetLinearDepth(traceZ, gbufferProjectionInverse);
		
		if (traceZ >= 1.0) {
		#endif
			traceZ = texture2D(depthtex, pos.xy).r;
			zDelta = -tracePos.z - GetLinearDepth(traceZ, projectionInverse);
		#ifdef VOXY
		}
		#endif

		shadow *= 1.0 - smoothstep(0.0, 0.5, zDelta) * smoothstep(thickness + 1.0, thickness, zDelta);
		thickness += 0.5;
	}

    #ifdef OVERWORLD
	vec3 shadowCol = ambientCol / mix(ambientCol, lightCol, shadowMask);
    #else
    vec3 shadowCol = endAmbientCol / mix(endAmbientCol, endLightCol, shadowMask);
    #endif

	return mix(shadowCol, vec3(1.0), shadow);
}