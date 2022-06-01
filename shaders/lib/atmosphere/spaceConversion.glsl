float getLogarithmicDepth(float dist) {
	return (far * (dist - near)) / (dist * (far - near));
}

float getLinearDepth2(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

vec4 getViewSpace(float depth, vec2 coord) {
	vec4 viewPos = gbufferProjectionInverse * (vec4(coord, depth, 1.0) * 2.0 - 1.0);
	viewPos /= viewPos.w;

	return viewPos;
}

vec4 getWorldSpace(float depth, vec2 coord) {
	vec4 viewPos = getViewSpace(depth, coord);

	vec4 wpos = gbufferModelViewInverse * viewPos;
	wpos /= wpos.w;
	
	return wpos;
}