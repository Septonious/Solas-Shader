float getNoise(vec3 pos){
	float noise  = texture2D(noisetex, (pos.xz + pos.y) * 0.002).r * 0.7;
		  noise += texture2D(noisetex, (pos.xz + pos.y) * 0.004).r * 0.6;
		  noise += texture2D(noisetex, (pos.xz + pos.y) * 0.008).r * 0.5;

	return noise;
}

float getCaustics(vec3 pos){
	float h0 = getNoise(pos + frameTimeCounter * 0.5);
	float h1 = getNoise(pos + vec3(1.0, 0.0, 0.0) - frameTimeCounter * 0.4);
	float h2 = getNoise(pos + vec3(-1.0, 0.0, 0.0) + frameTimeCounter * 0.3);
	float h3 = getNoise(pos + vec3(0.0, 0.0, 1.0) - frameTimeCounter * 0.2);
	float h4 = getNoise(pos + vec3(0.0, 0.0, -1.0) + frameTimeCounter * 0.1);
	
	float caustic = max((1.0 - abs(0.5 - h0)) * (1.0 - (abs(h1 - h2) + abs(h3 - h4))), 0.0);

	return pow2(caustic);
}