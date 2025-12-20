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
	kpIndex = 1;
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
		float tiltFactor = 0.1 + kpIndex * 0.15;
		worldPos.xz += worldPos.y * vec2(tiltFactor, tiltFactor * 2.);

		//Altitude factor. Makes the aurora closer to you when you're ascending
		float altitudeFactor = clamp(cameraPosition.y * 0.005, 0.0, 24.0);

        float accumulatedNoise = 0.0;
        float northSouthStretching = 0.5;

		for (int i = 0; i < samples; i++) {
			vec3 planeCoord = worldPos * ((24.0 + currentStep * (14.0 + kpIndex * 5.0) - altitudeFactor) / worldPos.y) * 0.05;
			vec2 offsetNoiseCoord = planeCoord.xz + cameraPosition.xz * 0.00005;
			float offsetNoise = texture2D(noisetex, (offsetNoiseCoord + frameTimeCounter * 0.0001) * 0.025).r;
				  offsetNoise = max(offsetNoise - 0.5, 0.0);
				 planeCoord *= 0.5 + offsetNoise;
			vec2 coord = planeCoord.xz + cameraPosition.xz * 0.0001;

			//We don't want the aurora to render infintely, we also want it to be closer to the north when Kp is low
			float auroraNorthBias = clamp((-planeCoord.x * 0.5 - planeCoord.z) * 0.25 * (10.0 - min(kpIndex, 1.0) * 9.0), pow5(kpIndex), 1.0);
			float auroraDistanceFactor = clamp(1.0 - length(planeCoord.xz) * 0.075, 0.0, 1.0) * auroraNorthBias;

			if (auroraDistanceFactor > 0.0) {
                coord.y *= northSouthStretching;
                float stripesOctave = texture2D(noisetex, coord * 0.0025 + frameTimeCounter * 0.00003).b;
                coord.y /= northSouthStretching;
                float detailOctave = texture2D(noisetex, coord * 0.250 - frameTimeCounter * 0.00009).r;
				float midOctave = texture2D(noisetex, coord * 0.025 - frameTimeCounter * 0.00006).r;
				float midOctaveM = max(midOctave - 0.45, 0.0);
				float midOctaveM2 = max(midOctave - 0.55, 0.0);

				float arcNoise = stripesOctave * 4.5 + detailOctave * 2.0;
					  arcNoise = max(0.75 - 1.5 * abs(arcNoise - 3.0 - midOctaveM * 5.0), 0.0);
					  arcNoise *= arcNoise * arcNoise * 0.75;

				float blobNoise = midOctaveM * (0.25 + detailOctave * 2.75);
					  blobNoise = max(blobNoise - 0.075 + stripesOctave * 0.125, 0.0) * detailOctave;

                float totalNoise = arcNoise + blobNoise;

                vec3 lowA = vec3(0.05, 1.55, 0.40);
                vec3 upA = vec3(0.65 + midOctaveM * 5.0 * (1.0 + kpIndex * 2.0), 0.30, 1.05);
                vec3 auroraA = fmix(lowA, upA, pow(currentStep, 0.66));

                vec3 lowB = vec3(0.40, 1.55, 0.05);
                vec3 upB = vec3(1.25, 0.05, 0.70);
                vec3 auroraB = fmix(lowB, upB, pow(currentStep, 0.45));

                float colorMixer = 0.0;

                vec3 totalAurora = mix(auroraA, auroraB, colorMixer) * exp2(-4.0 * i * sampleStep);

				aurora += totalAurora * totalNoise * sqrt(auroraDistanceFactor);
			}
			currentStep += sampleStep;
		}

		color += aurora * visibility * sampleStep;
	}
}