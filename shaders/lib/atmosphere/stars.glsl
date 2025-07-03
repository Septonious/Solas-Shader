float getNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

void drawStars(inout vec3 color, in vec3 worldPos, in vec3 sunVec, inout vec3 stars, in float VoU, in float VoS, in float caveFactor, in float nebulaFactor, in float volumetricClouds, float size) {
	#ifdef OVERWORLD
	float visibility = mix(0.5, 0.5 - timeBrightnessSqrt * 0.5, sunVisibility) * (1.0 - wetness) * (1.0 - volumetricClouds) * pow(VoU, 0.5) * caveFactor;
	#else
	float visibility = (0.4 - nebulaFactor * 0.2) * (1.0 - volumetricClouds);
	#endif

	if (0 < visibility) {
		vec2 planeCoord0 = worldPos.xz / (length(worldPos.y) + length(worldPos.xz));
			 planeCoord0 += cameraPosition.xz * 0.00001;
			 planeCoord0 += frameTimeCounter * 0.0005;
			 planeCoord0 = floor(planeCoord0 * 600.0 * STAR_AMOUNT) / (600.0 * STAR_AMOUNT);

		vec2 planeCoord1 = worldPos.xz / (length(worldPos.y) + length(worldPos.xz));
			 planeCoord1 *= size;
			 planeCoord1 += cameraPosition.xz * 0.00001;
			 planeCoord1 += frameTimeCounter * 0.0005;
			 planeCoord1 = floor(planeCoord1 * 1000.0 * STAR_AMOUNT) / (1000.0 * STAR_AMOUNT);

			 #if defined END && defined END_VORTEX
			 if (0.7 < VoS) {
				vec3 sunVec = mat3(gbufferModelViewInverse) * sunVec;
				vec2 sunCoord = sunVec.xz / (sunVec.y + length(sunVec));
				vec2 planeCoord2 = worldPos.xz / (length(worldPos) + worldPos.y) - sunCoord;
				float spiral1 = getSpiralWarping(planeCoord2) * clamp(VoU, 0.0, 1.0);
				planeCoord0 += spiral1 * 0.0005;
				planeCoord0 *= 0.25;
				planeCoord1 += spiral1 * 0.0005;
				planeCoord1 *= 0.25;
			 }
			 #endif

		float smallStars = getNoise(planeCoord0 + 10.0);
			  smallStars*= getNoise(planeCoord0 + 14.0);
			  smallStars = clamp(smallStars - (0.75 - nebulaFactor * 0.1), 0.0, 1.0);
			  smallStars *= visibility * STAR_BRIGHTNESS * 7.0;
			  smallStars *= smallStars;

		float bigStars = getNoise(planeCoord1 + 11.0);
			  bigStars*= getNoise(planeCoord1 + 13.0);
			  bigStars*= getNoise(planeCoord1 + 15.0);
			  bigStars = clamp(bigStars - (0.75 - nebulaFactor * 0.1), 0.0, 1.0);
			  bigStars *= visibility * STAR_BRIGHTNESS * 21.0;
			  bigStars *= bigStars;

		stars = vec3(smallStars) + vec3(bigStars);

		#ifdef OVERWORLD
		stars *= lightNight;
		#else
		stars *= endLightColSqrt * 0.5;
		#endif

		color += stars * visibility;
	}
}