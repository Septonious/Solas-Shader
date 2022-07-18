float getNoise(vec3 pos){
	pos.xz += pos.y;

	float noise  = texture2D(noisetex, (pos.xz + frameTimeCounter * 0.4) * 0.002).r * 1.1;
		  noise += texture2D(noisetex, (pos.xz - frameTimeCounter * 0.5) * 0.006).r * 0.9;
		  noise += texture2D(noisetex, (pos.xz + frameTimeCounter * 0.6) * 0.010).r * 0.8;

	return noise * 1.5;
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