float getNoise(vec3 pos){
	#ifdef BLOCKY_CLOUDS
	float noise  = texture2D(noisetex, (pos.xz - frameTimeCounter * 0.2 + pos.y) * 0.001).r;
		  noise += texture2D(noisetex, (pos.xz + frameTimeCounter * 0.3 + pos.y) * 0.004).r * 0.50;
		  noise += texture2D(noisetex, (pos.xz - frameTimeCounter * 0.4 + pos.y) * 0.012).r * 0.25;
	#else
	float noise  = texture2D(shadowcolor1, (pos.xz + frameTimeCounter * 0.1 + pos.y) * 0.002).r * 0.8;
		  noise += texture2D(shadowcolor1, (pos.xz - frameTimeCounter * 0.2 + pos.y) * 0.004).r * 0.9;
		  noise += texture2D(shadowcolor1, (pos.xz + frameTimeCounter * 0.3 + pos.y) * 0.006).r;
		  noise += texture2D(shadowcolor1, (pos.xz - frameTimeCounter * 0.4 + pos.y) * 0.008).r * 1.1;
	#endif

	return noise * 5.0;
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