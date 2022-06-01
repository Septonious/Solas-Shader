float getNoise(vec3 pos){
	float noise  = texture2D(noisetex, (pos.xz + pos.y) * 0.005).r * 0.7;
		  noise += texture2D(noisetex, (pos.xz + pos.y) * 0.010).r * 0.6;
		  noise += texture2D(noisetex, (pos.xz + pos.y) * 0.020).r * 0.5;

	return noise;
}

vec2 getRefraction(vec2 coord, vec3 pos){
	float h1 = getNoise(pos + vec3(1.0, 0.0, 0.0) - frameTimeCounter * 0.5);
	float h2 = getNoise(pos + vec3(-1.0, 0.0, 0.0) + frameTimeCounter * 0.4);
	float h3 = getNoise(pos + vec3(0.0, 0.0, 1.0) - frameTimeCounter * 0.3);
	float h4 = getNoise(pos + vec3(0.0, 0.0, -1.0) + frameTimeCounter * 0.2);

	vec2 noise = vec2(h2 - h1, h4 - h3);

	return clamp(coord + noise * 0.015, vec2(0.0), vec2(1.0));
}