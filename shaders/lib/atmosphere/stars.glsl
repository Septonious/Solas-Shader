float getNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

void drawStars(inout vec3 color, in vec3 worldPos, in float VoU, in float VoS, in float caveFactor, in float nebulaFactor, in float occlusion, in float size) {
	#ifdef OVERWORLD
	float visibility = moonVisibility * (1.0 - wetness) * pow(VoU, 0.5) * caveFactor;
	#else
	float visibility = 1.0;
	#endif

	visibility *= 1.0 - occlusion;

	if (0 < visibility) {
		vec2 planeCoord = worldPos.xz / (length(worldPos.y) + length(worldPos.xyz));
			 planeCoord *= size;
			 #ifdef END_BLACK_HOLE
			 float baseRing = pow10(pow32(VoS));

			 planeCoord *= clamp(1.0 - baseRing * 4.0, 0.0, 1.0);
			 planeCoord += baseRing;
			 #endif
			 planeCoord += cameraPosition.xz * 0.00001;
			 planeCoord += frameTimeCounter * 0.001;
		const float amount = STAR_AMOUNT;
		vec2 planeCoord0 = floor(planeCoord * 500.0 * amount) / (500.0 * amount);
		vec2 planeCoord1 = floor(planeCoord * 1000.0 * amount) / (1000.0 * amount);

		float starNoise = getNoise(planeCoord0 + 8.0);
			  starNoise*= getNoise(planeCoord1 + 14.0);

        float stars = clamp(starNoise - (0.825 - nebulaFactor * 0.125), 0.0, 1.0);
			  stars *= stars * stars * 512.0;
			  stars = clamp(stars, 0.0, 16.0);

		#ifdef OVERWORLD
		if (moonVisibility > 0.0) {
			float nebulaNoise = max(0.0, texture2D(noisetex, planeCoord * 0.25).r - 0.25) * VoU * pow4(moonVisibility) * (1.0 - wetness);
			color *= 1.0 + nebulaNoise;
			stars *= 1.0 + nebulaNoise;
		}
		color += (stars + pow2(max(starNoise - 0.95, 0.0)) * 2048.0) * lightNight * visibility * STAR_BRIGHTNESS;
		#else
		#ifdef END_BLACK_HOLE
		float hole = pow(pow4(pow32(VoS)), END_BLACK_HOLE_SIZE);
		hole *= hole;

		stars *= 1.0 - hole;
		#endif

		color = mix(color, color * (4.0 + pow4(stars)) * visibility * STAR_BRIGHTNESS, min(1.0, stars));
		#endif
	}
}