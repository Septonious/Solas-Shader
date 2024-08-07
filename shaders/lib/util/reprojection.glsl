vec2 Reprojection(vec3 pos) {
	pos = pos * 2.0 - 1.0;

	vec4 viewPosPrev = gbufferProjectionInverse * vec4(pos, 1.0);
		 viewPosPrev /= viewPosPrev.w;
		 viewPosPrev = gbufferModelViewInverse * viewPosPrev;

	vec3 cameraOffset = cameraPosition - previousCameraPosition;
		 cameraOffset *= float(pos.z > 0.56);

	vec4 previousPosition = viewPosPrev + vec4(cameraOffset, 0.0);
		 previousPosition = gbufferPreviousModelView * previousPosition;
		 previousPosition = gbufferPreviousProjection * previousPosition;

	return previousPosition.xy / previousPosition.w * 0.5 + 0.5;
}