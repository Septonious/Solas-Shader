void drawAurora(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor, in float vc, in float pc) {
	//The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
    float kpIndex = abs(worldDay % 9 - worldDay % 4);
          kpIndex = kpIndex - int(kpIndex == 1) + int(kpIndex > 7 && worldDay % 10 == 0);
          kpIndex = min(max(kpIndex, 0), 9);

	//Total visibility of aurora based on multiple factors
	float visibility = pow6(moonVisibility) * (1.0 - wetness) * caveFactor * (1.0 - pc * 0.75) * pow2(1.0 - vc) * AURORA_BRIGHTNESS;

	#ifdef AURORA_FULL_MOON_VISIBILITY
	kpIndex += float(moonPhase == 0) * 3;
	#endif

	#ifdef AURORA_COLD_BIOME_VISIBILITY
	kpIndex += isSnowy * 4;
	#endif

    #ifdef AURORA_ALWAYS_VISIBLE
    visibility = 1.0;
	kpIndex = 9.0;
    #endif

	//Aurora tends to get brighter and dimmer when plasma arrives or fades away
	float pulse = clamp(cos(sin(frameTimeCounter * 0.1) * 0.3 + frameTimeCounter * 0.07), 0.0, 1.0);
	float longPulse = clamp(sin(cos(frameTimeCounter * 0.01) * 0.6 + frameTimeCounter * 0.04), -1.0, 1.0);

	kpIndex *= 1.0 + longPulse * 0.5;
	kpIndex /= 9.0;
	visibility *= kpIndex;

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

		for (int i = 0; i < samples; i++) {
			vec3 planeCoordStatic = worldPos * ((16.0 + currentStep * 5.0 - altitudeFactor) / worldPos.y) * 0.025;
			vec3 planeCoordDeform = worldPos * ((24.0 - kpIndex * 4.5 - pulse * kpIndex * 3.0 + currentStep * (5.0 + kpIndex * 9.0) - altitudeFactor) / worldPos.y) * 0.025;
			vec2 coordDeform = planeCoordDeform.xz + cameraPosition.xz * 0.0001;

			//We don't want the aurora to render infintely, we also want it to be closer to the north when Kp is low
			float auroraNorthBias = clamp((-planeCoordStatic.x - planeCoordStatic.z) * 0.25 * (10.0 - min(kpIndex, 1.0) * 9.0), pow5(kpIndex), 1.0);
			float auroraDistanceFactor = clamp(1.0 - length(planeCoordStatic.xz) * (0.1 + kpIndex * 0.1), 0.0, 1.0) * auroraNorthBias;

			if (auroraDistanceFactor > 0.0) {
				float deformationNoise = max(0.0, texture2D(noisetex, coordDeform * 0.01 + frameTimeCounter * 0.00025).b - 0.5);

				vec3 planeCoord = worldPos * ((24.0 - kpIndex * 4.5 - pulse * longPulse * kpIndex * deformationNoise * 6.0 + currentStep * (10.0 - 7.5 * deformationNoise + kpIndex * 9.0) - altitudeFactor) / worldPos.y) * 0.025;
				vec2 coord = planeCoord.xz + cameraPosition.xz * 0.0001;
				float blobNoise = max(0.0, texture2D(noisetex, coord * 0.0075 + frameTimeCounter * 0.0001).b - 0.25 - kpIndex * 0.1 + pulse * 0.1);
				float baseNoise = texture2D(noisetex, coord * 0.005 - deformationNoise * 0.002 + frameTimeCounter * 0.00006).b * 2.50;
					  baseNoise+= texture2D(noisetex, coord * 0.100 + deformationNoise * 0.001 - frameTimeCounter * 0.00012).r * 2.75;
				baseNoise = max(1.0 - 2.0 * abs(baseNoise - 3.0) - (1.0 - kpIndex * 0.5) * 0.5, 0.0);
				baseNoise *= baseNoise;
				float detailNoise = max(0.0, texture2D(noisetex, coord * (0.050 + kpIndex * 0.100 + pulse * 0.025) + deformationNoise * 0.003 + frameTimeCounter * 0.00024).b - 0.2);

				//Add all noise iterations together
				float totalNoise = baseNoise * pow(1.0 - currentStep, 1.0 + (3.0 + pulse * 4.0) * deformationNoise);
					  totalNoise *= 0.5 + detailNoise * 0.5;
					  totalNoise += blobNoise * (0.2 + pulse * 0.2);

				//Now let's add some colors! Based on low frequency noise, the aurora is either blue-green or red-yellow
				float colorMixer = clamp(texture2D(noisetex, coord * 0.00125).b * kpIndex * kpIndex * (0.25 + pulse * 0.75), 0.0, 1.0);

				vec3 auroraColor1 = mix(vec3(0.6, 4.7 - pulse * 0.5, 0.2), vec3(3.4, 0.1, 1.5 + pulse * 0.5), pow(currentStep, 0.25));
					 auroraColor1 *= exp2(-4.0 * i * sampleStep);
				vec3 auroraColor2 = mix(vec3(0.7, 4.2, 0.1), vec3(1.9 + currentStep, 0.4, 6.7), sqrt(currentStep));
					 auroraColor2 *= exp2(-5.5 * i * sampleStep);
				vec3 auroraColor = mix(auroraColor2, auroraColor1, colorMixer) * (1.0 + pow8(1.0 - currentStep));
				aurora += auroraColor * totalNoise * auroraDistanceFactor * sampleStep;
			}
			currentStep += sampleStep;
		}

		color += aurora * visibility;
	}
}