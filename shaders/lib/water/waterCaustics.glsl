float getNoise(vec3 pos){
	pos.xz += pos.y;

	float noise = texture2D(shadowcolor1, (pos.xz - frameTimeCounter * 0.2) * 0.002).r;
		  noise+= texture2D(shadowcolor1, (pos.xz + frameTimeCounter * 0.3) * 0.008).r * 0.50;
		  noise+= texture2D(shadowcolor1, (pos.xz - frameTimeCounter * 0.4) * 0.032).r * 0.25;

	return noise * 8.0;
}

float getCaustics(vec3 pos){
	pos.xz += vec2(WATER_NORMAL_OFFSET, 0.0);
	float harmonic1 = getNoise(pos);
	pos.xz += vec2(-WATER_NORMAL_OFFSET, 0.0);
	float harmonic2 = getNoise(pos);
	pos.xz += vec2(0.0, WATER_NORMAL_OFFSET);
	float harmonic3 = getNoise(pos);
	pos.xz += vec2(0.0, -WATER_NORMAL_OFFSET);
	float harmonic4 = getNoise(pos);

	return clamp(1.0 - (abs(harmonic1 - harmonic2) + abs(harmonic3 - harmonic4)), 0.0, 1.0);
}