void drawAurora(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor) {
	//The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
	float kpIndex = abs(worldDay % 9 - worldDay % 4) + int(worldDay == 0) * 5 + int(worldDay != 0 && worldDay % 100 == 0) * 9;

	//Total visibility of aurora based on multiple factors
	float visibility = pow6(moonVisibility) * (1.0 - wetness) * caveFactor * AURORA_BRIGHTNESS;

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
	visibility *= kpIndex * 2.0;

	if (visibility > 0.5) { //Rejects kp=1
		vec3 aurora = vec3(0.0);

        float dither = Bayer8(gl_FragCoord.xy);
        #ifdef TAA
        	  dither = fract(frameTimeCounter * 16.0 + dither);
        #endif

		//Determines the quality of aurora. Since it stretches a lot during strong geomagnetic storms, we need more samples
		int samples = int(kpIndex * 16);
		float sampleStep = 1.0 / samples;
		float currentStep = dither * sampleStep;

		//Aurora tends to get brighter and dimmer when plasma arrives or fades away
		float pulse = clamp(cos(sin(frameTimeCounter * 0.1) * 0.7 + frameTimeCounter * 0.3), 0.0, 1.0);

		//Tilt factor. The stronger the geomagnetic storm, the less Aurora tilts towards the North
		float tiltFactor = 0.05 + kpIndex * 0.15;
		worldPos.xz += worldPos.y * tiltFactor;

		//Altitude factor. Makes the aurora closer to you when you're ascending
		float altitudeFactor = clamp(cameraPosition.y * 0.004, 0.0, 9.0);

		for (int i = 0; i < samples; i++) {
			vec3 planeCoordDeform = worldPos * ((16.0 - kpIndex * 9.0 + currentStep * (5.0 + kpIndex * 18.0) - altitudeFactor) / worldPos.y) * 0.025;

			if (planeCoordDeform.x + planeCoordDeform.z < pow3(kpIndex) * 5.0) {
				vec2 coordDeform = planeCoordDeform.xz + cameraPosition.xz * 0.0001;

				//We don't want the aurora to render infintely
				float auroraDistanceFactor = max(1.0 - length(planeCoordDeform.xz) * 0.33, 0.0);

				if (auroraDistanceFactor > 0.0) {
					float deformationNoise = max(0.0, texture2D(noisetex, coordDeform * 0.01 + frameTimeCounter * 0.00025).b - 0.5);
					float blobNoise = max(0.0, texture2D(noisetex, coordDeform * 0.005 + frameTimeCounter * 0.0001).b - 0.25 - (1.0 - kpIndex) * 0.5);

					vec3 planeCoord = worldPos * ((24.0 - kpIndex * 9.0 + currentStep * (10.0 - 7.5 * deformationNoise + kpIndex * 18.0) - altitudeFactor) / worldPos.y) * 0.025;
					vec2 coord = planeCoord.xz + cameraPosition.xz * 0.0001;
					float baseNoise = texture2D(noisetex, coord * 0.005 - deformationNoise * 0.002 + frameTimeCounter * 0.00006).b * 2.50;
						  baseNoise+= texture2D(noisetex, coord * 0.100 + deformationNoise * 0.001 - frameTimeCounter * 0.00012).r * 2.75;
					baseNoise = max(1.0 - 2.0 * abs(baseNoise - 3.0) - (1.0 - kpIndex) * 0.5, 0.0);
					baseNoise *= baseNoise;
					float detailNoise = max(0.0, texture2D(noisetex, coord * (0.050 + kpIndex * 0.025 + pulse * 0.025) + deformationNoise * 0.003 + frameTimeCounter * 0.0002).b - 0.2);

					//Add all noise iterations together
					float totalNoise = baseNoise * pow(1.0 - currentStep, 1.0 + (3.0 + pulse * 4.0) * deformationNoise);
						  totalNoise *= 0.5 + detailNoise * 0.5;
						  totalNoise += blobNoise * (0.15 + pulse * 0.15);

					//Now let's add some colors! Based on low frequency noise, the aurora is either blue-green or red-yellow
					float colorMixer = clamp(texture2D(noisetex, coord * 0.00125).b * 1.5 * kpIndex, 0.0, 1.0);

					vec3 auroraColor1 = mix(vec3(0.6, 4.0, 0.4), vec3(3.4, 0.1, 1.5), pow(currentStep, 0.25));
						 auroraColor1 *= exp2(-3.0 * i * sampleStep);
					vec3 auroraColor2 = mix(vec3(0.3, 4.0, 0.7), vec3(1.9 + currentStep, 0.4, 3.7), sqrt(currentStep));
						 auroraColor2 *= exp2(-4.5 * i * sampleStep);

					vec3 auroraColor = mix(auroraColor2, auroraColor1, pow2(colorMixer));
					aurora += auroraColor * totalNoise * auroraDistanceFactor * sampleStep;
				}
			}
			currentStep += sampleStep;
		}

		color += aurora * visibility;
	}
}