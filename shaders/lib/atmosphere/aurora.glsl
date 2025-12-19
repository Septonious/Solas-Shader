void drawAurora(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor, in float vc, in float pc) {
	//The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
    float kpIndex = abs(worldDay % 9 - worldDay % 4);
          kpIndex = kpIndex - int(kpIndex == 1) + int(kpIndex > 7 && worldDay % 10 == 0);
          kpIndex = min(max(kpIndex, 0) + isSnowy * 4, 9);

	//Total visibility of aurora based on multiple factors
	float visibility = pow6(moonVisibility) * (1.0 - wetness) * caveFactor * (1.0 - pc * 0.75) * pow2(1.0 - vc);

	//Aurora tends to get brighter and dimmer when plasma arrives or fades away
    float pulse = clamp(cos(sin(frameTimeCounter * 0.1) * 0.3 + frameTimeCounter * 0.07), 0.0, 1.0);
    float longPulse = clamp(sin(cos(frameTimeCounter * 0.01) * 0.6 + frameTimeCounter * 0.04), -1.0, 1.0);

	kpIndex *= 1.0 + longPulse * 0.25;
	kpIndex /= 9.0;
	visibility *= kpIndex * (1.0 + max(longPulse * 0.5, 0.0) + kpIndex * kpIndex * 0.5);
    visibility = min(visibility, 2.0) * AURORA_BRIGHTNESS;

	if (visibility > 0.1) {
		vec3 aurora = vec3(0.0);

        float dither = Bayer8(gl_FragCoord.xy);
        #ifdef TAA
        	  dither = fract(frameTimeCounter * 16.0 + dither);
        #endif

		//Determines the quality of aurora. Since it stretches a lot during strong geomagnetic storms, we need more samples
		int samples = int(8 + kpIndex * 8);
		float sampleStep = 1.0 / samples;
		float currentStep = dither * sampleStep;

		//Tilt factor. The stronger the geomagnetic storm, the less Aurora tilts towards the North
		float tiltFactor = 0.05 + kpIndex * 0.15;
		worldPos.xz += worldPos.y * tiltFactor;

		//Altitude factor. Makes the aurora closer to you when you're ascending
		float altitudeFactor = clamp(cameraPosition.y * 0.004, 0.0, 9.0);

        float accumulatedNoise = 0.0;
        float northSouthStretching = 0.4 + pulse * 0.2;
        float lineNoiseCoeff = 3.0 + pulse * 4.0; //[1.0 - 7.5]
        float whirlNoiseCoeff = 25.0 + pulse * 25.0; //[20.0 - 100.0]

		for (int i = 0; i < samples; i++) {
			vec3 planeCoord = worldPos * ((20.0 + currentStep * (14.0 + accumulatedNoise * 9.0 + kpIndex * 5.0) - altitudeFactor) / worldPos.y) * 0.05;
			vec2 coord = planeCoord.xz + cameraPosition.xz * 0.0001;

			//We don't want the aurora to render infintely, we also want it to be closer to the north when Kp is low
			float auroraNorthBias = clamp((-planeCoord.x * 0.5 - planeCoord.z) * 0.25 * (10.0 - min(kpIndex, 1.0) * 9.0), pow5(kpIndex), 1.0);
			float auroraDistanceFactor = clamp(1.0 - length(planeCoord.xz) * 0.075, 0.0, 1.0) * auroraNorthBias;

			if (auroraDistanceFactor > 0.0) {
                coord.y *= northSouthStretching;
                float baseOctaveA = texture2D(noisetex, coord * 0.002 + frameTimeCounter * 0.00006).b;
                coord.y /= northSouthStretching;
                float baseOctaveB = texture2D(noisetex, coord * 0.100 - frameTimeCounter * baseOctaveA * 0.00012).r;
                float baseOctaveC_u = texture2D(noisetex, coord * 0.025 + frameTimeCounter * baseOctaveA * 0.00008 + 0.5).r;
                float baseOctaveC = max(baseOctaveC_u - 0.5, 0.0);
				float arcNoise = baseOctaveA * 6.0;
					  arcNoise*= baseOctaveB * 4.0;
					  arcNoise = max(1.0 - abs(arcNoise - 3.5 - baseOctaveB * baseOctaveB * lineNoiseCoeff - baseOctaveC * whirlNoiseCoeff), 0.0);
					  arcNoise *= arcNoise * 0.5;
                float blobNoise = max(0.0, baseOctaveB * baseOctaveB * (0.33 + baseOctaveA * 0.67) - 0.125);
                float detailNoise = texture2D(noisetex, coord * 0.150 - frameTimeCounter * 0.0024).b;
                float totalNoise = (arcNoise * (0.75 + detailNoise * 16.0 * baseOctaveC) + blobNoise * 0.75);

                vec3 lowA = vec3(0.05, 1.55, 0.40);
                vec3 upA = vec3(0.65 - baseOctaveC * baseOctaveC * 0.20, 0.30, 1.05 + baseOctaveC * baseOctaveC * 0.20);
                vec3 auroraA = fmix(lowA, upA, pow(currentStep, 0.66));
                     auroraA *= exp2(-(3.0 + baseOctaveC * 25.0) * i * sampleStep);

                vec3 lowB = vec3(0.40, 1.55, 0.05);
                vec3 upB = vec3(1.25 + baseOctaveC * pulse * 0.5, 0.05, 0.70);
                vec3 auroraB = fmix(lowB, upB, pow(currentStep, 0.45));
                     auroraB *= exp2(-(3.0 + baseOctaveC * 25.0) * i * sampleStep);

                float colorMixer = min(max(baseOctaveC_u - 0.45 + kpIndex * 0.1, 0.0) * 16.0 * kpIndex * kpIndex, 1.0) * (0.25 + pulse * 0.75);

                vec3 totalAurora = mix(auroraA, auroraB, colorMixer);

				aurora += totalAurora * totalNoise * sqrt(auroraDistanceFactor);
                accumulatedNoise += max(baseOctaveC * baseOctaveC * 25.0 - 0.075, 0.0);
			}
			currentStep += sampleStep;
		}

		color += aurora * visibility * sampleStep;
	}
}