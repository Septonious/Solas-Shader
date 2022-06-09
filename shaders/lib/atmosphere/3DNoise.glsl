float getTextureNoise(vec3 pos) {
	pos *= 0.2;
	pos.xz *= 0.2;

	vec3 u = floor(pos);
	vec3 v = fract(pos);

	vec2 uv = u.xz + v.xz + u.y * 16.0;

	vec2 coord = uv * 0.015625;
	float a = texture2D(depthtex2, coord).r;
	float b = texture2D(depthtex2, coord + 0.25).r;
		
	return mix(a, b, v.y);
}