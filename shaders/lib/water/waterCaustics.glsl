float getNoise(vec3 pos){
	float noise  = texture2D(noisetex, (pos.xz + pos.y + frameTimeCounter * 0.4) * 0.002).r;
		  noise += texture2D(noisetex, (pos.xz + pos.y - frameTimeCounter * 0.5) * 0.004).r * 0.9;
		  noise += texture2D(noisetex, (pos.xz + pos.y + frameTimeCounter * 0.6) * 0.008).r * 0.8;

	return noise;
}

float getCaustics(vec3 pos){
	float h0 = getNoise(pos);
	float h1 = getNoise(pos + vec3(1.0, 0.0, 0.0));
	float h2 = getNoise(pos + vec3(-1.0, 0.0, 0.0));
	float h3 = getNoise(pos + vec3(0.0, 0.0, 1.0));
	float h4 = getNoise(pos + vec3(0.0, 0.0, -1.0));
	
	float caustic = max((1.0 - abs(0.5 - h0)) * (1.0 - (abs(h1 - h2) + abs(h3 - h4))), 0.0);

	return caustic;
}