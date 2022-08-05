vec3 ToShadow(vec3 shadowPos) {
	vec3 shadowpos = mat3(shadowModelView) * shadowPos + shadowModelView[3].xyz;
	
	return projMAD(shadowProjection, shadowpos);
}