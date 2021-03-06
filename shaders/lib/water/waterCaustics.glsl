float getNoise(vec3 pos){
	pos.xz += pos.y;

	float noise  = texture2D(noisetex, (pos.xz - frameTimeCounter * 0.2) * 0.001).r;
		  noise += texture2D(noisetex, (pos.xz + frameTimeCounter * 0.3) * 0.002).r * 0.75;
		  noise += texture2D(noisetex, (pos.xz - frameTimeCounter * 0.4) * 0.008).r * 0.50;

	return noise * 3.0;
}

float getCaustics(vec3 pos){
	pos.xz += vec2(1.0, 0.0);
	float harmonic1 = getNoise(pos);
	pos.xz += vec2(-1.0, 0.0);
	float harmonic2 = getNoise(pos);
	pos.xz += vec2(0.0, 1.0);
	float harmonic3 = getNoise(pos);
	pos.xz += vec2(0.0, -1.0);
	float harmonic4 = getNoise(pos);

	return clamp((1.0 - (abs(harmonic1 - harmonic2) + abs(harmonic3 - harmonic4))), 0.0, 1.0);
}