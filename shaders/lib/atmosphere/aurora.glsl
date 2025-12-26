float auroraDistortedNoise(
    vec2 uv,
    float time,
    float strength,
	float northSouthStretching,
	float eastWestStretching
) {
    vec2 baseUV = uv * vec2(northSouthStretching, eastWestStretching);
    	 baseUV.y += time * 0.050;
		 baseUV.x += time * 0.025;

    float n = texture2D(noisetex, baseUV).r * 2.0 - 1.0;
		  n *= strength;

    // Directional shear
    vec2 warpedUV = uv;
    	 warpedUV.x += n * 0.05;
    	 warpedUV.y += abs(n) * 0.10;

	float blobNoise = texture2D(noisetex, warpedUV * 2.0).r;
		  blobNoise = max(blobNoise - 0.4, 0.0) * 0.75;

	float detailOctave = texture2D(noisetex, uv * 25.0 + frameTimeCounter * 0.004).r;
		  detailOctave = pow2(detailOctave - 0.1) * 4.0;
	float stripeNoise = pow(blobNoise, 4.0 - blobNoise * 3.0) * 1024.0 * detailOctave;

    return blobNoise + stripeNoise;
}



void drawAurora(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor, in float vc, in float pc) {
	//The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
    float kpIndex = abs(worldDay % 9 - worldDay % 4);
          kpIndex = kpIndex - int(kpIndex == 1) + int(kpIndex > 7 && worldDay % 10 == 0);
          kpIndex = min(max(kpIndex, 0) + isSnowy * 4, 9);

	//Total visibility of aurora based on multiple factors
	float visibility = pow6(moonVisibility) * (1.0 - wetness) * caveFactor * (1.0 - pc) * pow2(1.0 - vc);

	//Aurora tends to get brighter and dimmer when plasma arrives or fades away
	float pulse = clamp(cos(sin(frameTimeCounter * 0.12) * 0.4 + frameTimeCounter * 0.11), 0.0, 1.0);
	float longPulse = clamp(sin(cos(frameTimeCounter * 0.04) * 0.6 + frameTimeCounter * 0.06), -1.0, 1.0);

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
		float tiltFactor = 0.15 + kpIndex * 0.15;
		worldPos.xz += worldPos.y * vec2(tiltFactor * (0.75 + pulse * 0.25), tiltFactor * (2.0 - longPulse));
		//Altitude factor. Makes the aurora closer to you when you're ascending
		float altitudeFactor = clamp(cameraPosition.y * 0.005, 0.0, 24.0);

        float accumulatedNoise = 0.0;
        float northSouthStretching = 2.0;
		float eastWestStretching = 1.0;

		for (int i = 0; i < samples; i++) {
			vec3 planeCoord = worldPos * ((10.0 + pow(clamp(VoU, 0.0, 1.0), 0.25) * 15.0 + currentStep * (10.0 + kpIndex * 5.0) - altitudeFactor) / worldPos.y) * 0.05;
			vec2 coord = planeCoord.xz + cameraPosition.xz * 0.0001;

			//We don't want the aurora to render infintely, we also want it to be closer to the north when Kp is low
			float auroraNorthBias = clamp((-planeCoord.x * 0.5 - planeCoord.z) * 0.25 + pow4(kpIndex) * 2.0, 0.0, 1.0);
			float auroraDistanceFactor = clamp(1.0 - length(planeCoord.xz) * 0.1, 0.0, 1.0) * auroraNorthBias;

			if (auroraDistanceFactor > 0.0) {
                coord.y *= 0.5;
                float totalNoise = auroraDistortedNoise(coord * 0.025, frameTimeCounter * 0.01, 0.25 + kpIndex * 0.5, northSouthStretching, eastWestStretching);
                coord.y /= 2.0;

                vec3 lowA = vec3(0.05, 1.55, 0.40);
                vec3 upA = vec3(0.65 + (1.0 + pulse) * pow3(kpIndex), 0.30, 1.05);
                vec3 auroraA = fmix(lowA, upA, pow(currentStep, 0.75 - kpIndex * 0.25)) * exp2(-4.0 * i * sampleStep);

				aurora += auroraA * totalNoise * sqrt(auroraDistanceFactor);
			}
			currentStep += sampleStep;
		}

		color += aurora * visibility * sampleStep;
	}
}