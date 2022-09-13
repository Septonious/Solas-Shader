#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)

#ifdef VL
float getLogarithmicDepth(float dist) {
	return (far * (dist - near)) / (dist * (far - near));
}

float getLinearDepth2(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

vec3 calculateWorldPos(float depth, vec2 coord) {
	vec4 viewPos = gbufferProjectionInverse * (vec4(coord, depth, 1.0) * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec4 wpos = gbufferModelViewInverse * viewPos;
	return (wpos / wpos.w).xyz;
}
#endif

vec3 calculateShadowPos(vec3 worldPos) {
    vec3 shadowPos = mat3(shadowModelView) * worldPos + shadowModelView[3].xyz;
		 shadowPos = projMAD(shadowProjection, shadowPos);
    float distb = sqrt(shadowPos.x * shadowPos.x + shadowPos.y * shadowPos.y);
    float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);

    shadowPos.xy /= distortFactor;
    shadowPos.z *= 0.2;
    
    return shadowPos * 0.5 + 0.5;
}