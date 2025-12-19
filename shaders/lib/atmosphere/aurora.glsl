void drawAurora(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor, in float vc, in float pc) {
    //The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
    float kpIndex = abs(worldDay % 9 - worldDay % 4);
          kpIndex = kpIndex - int(kpIndex == 1) + int(kpIndex > 7 && worldDay % 10 == 0);
          kpIndex = min(max(kpIndex, 0) + isSnowy, 9);

	//Total visibility of aurora based on multiple factors
	float visibility = pow6(moonVisibility) * (1.0 - wetness) * caveFactor * (1.0 - pc * 0.75) * pow2(1.0 - vc);

	//Aurora tends to get brighter and dimmer when plasma arrives or fades away
	float pulse = clamp(cos(sin(frameTimeCounter * 0.1) * 0.3 + frameTimeCounter * 0.07), 0.0, 1.0);
	float longPulse = clamp(sin(cos(frameTimeCounter * 0.01) * 0.6 + frameTimeCounter * 0.04), -1.0, 1.0);

	kpIndex *= 1.0 + longPulse * 0.25;
	kpIndex = 9;
	kpIndex /= 9.0;
	visibility *= kpIndex;
    visibility = min(visibility, 1.0) * AURORA_BRIGHTNESS;

	if (visibility > 0.1) {
		vec3 aurora = vec3(0.0);

        float dither = Bayer8(gl_FragCoord.xy);
        #ifdef TAA
        	  dither = fract(frameTimeCounter * 16.0 + dither);
        #endif

		//Time
	    float time = (worldTime + int(5 + mod(worldDay, 100)) * 24000) * 0.05;

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
			vec3 planeCoord = worldPos * ((24.0 - kpIndex * 8.0 + pulse * 8.0 + currentStep * (10.0 + kpIndex * 10.0) - altitudeFactor) / worldPos.y) * 0.025;

			//We don't want the aurora to render infintely, we also want it to be closer to the north when Kp is low
			float auroraNorthBias = clamp((-planeCoord.x * 0.5 - planeCoord.z * 1.5) * 0.25 * (10.0 - min(kpIndex, 1.0) * 9.0), pow5(kpIndex), 1.0);
			float auroraDistanceFactor = clamp(1.0 - length(planeCoord.xz) * (0.1 - kpIndex * 0.05), 0.0, 1.0) * auroraNorthBias;

			if (auroraDistanceFactor > 0.0) {
				vec2 coord = planeCoord.xz + cameraPosition.xz * 0.0001;
				float deformNoise = clamp(texture2D(noisetex, coord * 0.05 + time * 0.001).b - 0.35, 0.0, 1.0);
				vec3 planeCoordDeformed = worldPos * ((24.0 - kpIndex * 8.0 + pulse * 4.0 + currentStep * (15.0 + 5.0 * deformNoise + kpIndex * 5.0) - altitudeFactor) / worldPos.y) * 0.025;
				vec2 coordDeformed = planeCoordDeformed.xz + cameraPosition.xz * 0.0001;
				float baseNoise = texture2D(noisetex, coordDeformed * 0.0025 + time * 0.00006).b * (3.0 + longPulse * 0.5 - pulse * 0.25);
                float blobNoise = max(baseNoise * (0.5 - kpIndex * 0.25) - 0.2, 0.0) * (0.25 + pulse * 0.25);
					  baseNoise+= texture2D(noisetex, coordDeformed * 0.100 - time * 0.00012).r * (2.25 - longPulse * 0.5 + pulse * 0.25);
					  baseNoise = max(1.0 - 2.0 * abs(baseNoise - 3.0) - (1.0 - kpIndex * 0.5) * 0.5, 0.0);
					  baseNoise *= baseNoise;

				//Add all noise iterations together
				float octaveA = texture2D(noisetex, coordDeformed * 0.090 + frameTimeCounter * 0.0012).b;
				float octaveB = texture2D(noisetex, coordDeformed * 0.180 - frameTimeCounter * 0.0024).b;
				float totalNoise = baseNoise * (1.0 - currentStep);
					  totalNoise*= octaveA * (0.5 - pulse * 0.1) + (0.5 + pulse * 0.1);
					  totalNoise*= octaveB * (0.6 - pulse * 0.2) + (0.4 + pulse * 0.2);

				//Now let's add some colors! Based on low frequency noise, the aurora is either blue-green or red-yellow
				float colorMixerNoise = clamp(texture2D(noisetex, coord * 0.0025).b - 0.35, 0.0, 1.0);
				float colorMixer = clamp((colorMixerNoise + kpIndex * 0.15) * kpIndex * kpIndex * 2.0, 0.0, 1.0);

				vec3 lowerGreen = vec3(0.15 + pulse * 0.25, 1.45, 0.50);
				vec3 upperPurple = vec3(0.65 + colorMixerNoise, 0.10, 1.25);
				vec3 aurora1 = mix(lowerGreen, upperPurple, currentStep * 1.25) * totalNoise +
								mix(lowerGreen, upperPurple, 0.25 + blobNoise * blobNoise * 0.5) * blobNoise * 0.;
					 aurora1 *= exp2(-2.0 * i * sampleStep);

				vec3 lowerGreen2 = vec3(0.65 + pulse * 0.25, 1.90, 0.35);
				vec3 upperRed = vec3(1.8 - pulse * 0.2, 0.05, 0.75 + pulse * 0.2);
				vec3 aurora2 = mix(lowerGreen2, upperRed, pow(currentStep, 0.33)) * totalNoise +
								mix(lowerGreen2, upperRed, 0.35 + blobNoise * blobNoise * 0.4) * blobNoise * 0.;
					 aurora2 *= exp2(-1.5 * i * sampleStep);

				aurora += mix(aurora1, aurora2, colorMixer) * auroraDistanceFactor * sampleStep;
			}
			currentStep += sampleStep;
		}

		color += aurora * visibility * 5;
	}
}