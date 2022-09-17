vec3 ToShadow(vec3 worldPos) {
	vec3 shadowPos = mat3(shadowModelView) * worldPos + shadowModelView[3].xyz;
	
	return projMAD(shadowProjection, shadowPos);
}