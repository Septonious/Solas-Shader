float getAuroraNoise(vec2 coord) {
	float noise = texture2D(noisetex, coord * 0.0050 + frameTimeCounter * 0.00004).b * 3.0;
		  noise+= texture2D(noisetex, coord * 0.0025 - frameTimeCounter * 0.00008).b * 3.0;

	return max(1.0 - 2.0 * abs(noise - 3.0), 0.0);
}

void drawAurora(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor) {
	float kpIndex = abs(worldDay % 9 - worldDay % 4); //Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
	float visibility = pow6(1.0 - sunVisibility) * (1.0 - wetness) * caveFactor * AURORA_BRIGHTNESS;

	#ifdef OVERWORLD
	#ifdef AURORA_FULL_MOON_VISIBILITY
	kpIndex += float(moonPhase == 0) * 3;
	#endif

	#ifdef AURORA_COLD_BIOME_VISIBILITY
	kpIndex += isSnowy * 5;
	#endif
	#endif

    #ifdef AURORA_ALWAYS_VISIBLE
    visibility = 1.0;
	kpIndex = 9.0;
    #endif

	kpIndex = clamp(kpIndex, 0.0, 9.0) / 9.0;
	visibility *= kpIndex;

	if (visibility > 0.1) {
		vec3 aurora = vec3(0.0);

        float dither = Bayer8(gl_FragCoord.xy);

        #ifdef TAA
        dither = fract(frameTimeCounter * 16.0 + dither);
        #endif

		int samples = 8;
		float sampleStep = 1.0 / samples;
		float currentStep = dither * sampleStep;

		float pulse = sin(frameTimeCounter * 0.25); //Aurora tends to get brighter and dimmer when plasma arrives or fades away
		float tiltFactor = 0.05 + (1.0 - kpIndex) * 0.2; //Tilt factor. The stronger the geomagnetic storm, the less Aurora tilts towards the North

		for (int i = 0; i < samples; i++) {
			vec3 planeCoord = worldPos * ((16.0 - kpIndex * 8.0 + currentStep * (12.0 + abs(pulse * 6.0) + kpIndex * 4.0) - clamp(cameraPosition.y * 0.004, 0.0, 9.0)) / worldPos.y) * 0.025;
				 planeCoord.z += planeCoord.y * tiltFactor;
				 planeCoord.x += planeCoord.y * tiltFactor;
			vec2 offsetNoiseCoord = planeCoord.xz + cameraPosition.xz * 0.00005;
				 planeCoord *= 0.5 + texture2D(noisetex, (offsetNoiseCoord + frameTimeCounter * 0.0001) * 0.05).r * 0.5;

			if (planeCoord.x + planeCoord.z < kpIndex) {
				float fade = min(abs(planeCoord.x + planeCoord.z), 1.0);
				vec2 coord = planeCoord.xz + cameraPosition.xz * 0.0001;

				float noise = getAuroraNoise(coord + frameTimeCounter * 0.0008);
				
				if (noise > 0) {
					float noiseBase = noise;
					float auroraDistanceFactor = max(1.0 - length(planeCoord.xz) * 0.25, 0.0);

					noise *= texture2D(noisetex, coord * 0.125 + frameTimeCounter * 0.0008).b * (0.4 - pulse * 0.1) + (0.6 + pulse * 0.1);
					noise *= texture2D(noisetex, coord * 0.250 - frameTimeCounter * 0.0010).b * (0.5 - pulse * 0.2) + (0.5 + pulse * 0.2);
					noise *= noise * sampleStep * auroraDistanceFactor;
					noiseBase *= sampleStep * auroraDistanceFactor;

					float colorMixer = clamp(texture2D(noisetex, coord * 0.0025).b * 1.5, 0.0, 1.0);

					vec3 auroraColor1 = mix(vec3(0.6, 4.0, 0.4), vec3(3.4, 0.1, 1.5), pow(currentStep, 0.25));
						 auroraColor1 *= exp2(-3.0 * i * sampleStep);
					vec3 auroraColor2 = mix(vec3(0.3, 4.0, 0.7), vec3(1.9, 0.4, 3.7), pow(currentStep, 0.50));
						 auroraColor2 *= exp2(-4.5 * i * sampleStep);

					vec3 auroraColor = mix(auroraColor1, auroraColor2, pow3(colorMixer));
					vec3 auroraBlurredColor = auroraColor * noiseBase;
						 auroraColor *= noise;
						 auroraColor *= 1.0 + length(auroraColor);
						 auroraColor = auroraBlurredColor * (0.4 - pulse * 0.2) + auroraColor * (0.7 + pulse * 0.3);
						 auroraColor *= fade;
					aurora += auroraColor;
				}
			}
			currentStep += sampleStep;
		}

		color += aurora * visibility * (1.0 - clamp(pow(VoU, 0.6), 0.0, 0.7));
	}
}