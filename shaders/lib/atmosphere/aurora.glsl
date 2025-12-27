
float auroraDistortedNoise(vec2 coord, float pulse, float longPulse, float kpIndex) {
    // Low frequency noise
    vec2 flowUV = coord * 0.1;
    flowUV += vec2(
        sin(frameTimeCounter * 0.00006),
        cos(frameTimeCounter * 0.00004)
    );

    float flow = texture2D(noisetex, flowUV).r * 2.0 - 1.0;
    	  flow *= 3.0 + longPulse * 3.0;

    // Oscillatory warp (no long-term drift)
    vec2 warp;
    warp.x =  flow * 0.1 * sin(frameTimeCounter * 0.004 + flow);
    warp.y = -flow * 0.4 * cos(frameTimeCounter * 0.002);

    vec2 distortedCoord = coord + warp;

    // Overhead arc
    float zenithDist = abs(coord.y - 1.0);
    float arc = exp(-4.0 * zenithDist * zenithDist);

    arc *= 0.65 + 0.35 * flow;

    // Blurry background noise (aka folds)
    vec2 sheetCoord = vec2(
        distortedCoord.x * 1.25,
        distortedCoord.y * 0.5
    );

    sheetCoord.y += sin(frameTimeCounter * 0.0025 + distortedCoord.x * 0.5) * 0.02;

    float sheet = texture2D(noisetex, sheetCoord).r;
    	  sheet *= sheet * sheet * 2.0;

    // High frequency noise (aka rays)
    vec2 rayCoord = vec2(
        distortedCoord.x * 5.0,
        distortedCoord.y * 2.0
    );

    rayCoord.y += sin(frameTimeCounter * 0.0075 + distortedCoord.x * 2.0) * 0.05;

    float rays = texture2D(noisetex, rayCoord).r;
    	  rays = pow8(rays);

    float aurora = sheet * arc * (20.0 + 30.0 * pulse + 40.0 * pulse * longPulse + rays * 10000.0);
		  aurora *= max(pow(1.0 - abs(coord.x * 4.0), 4.0 - longPulse * 2.0 - kpIndex), 0.0);

    return aurora;
}


void drawAurora(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor, in float vc, in float pc) {
	//The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
    float kpIndex = abs(worldDay % 9 - worldDay % 4);
          kpIndex = kpIndex - int(kpIndex == 1) + int(kpIndex > 7 && worldDay % 10 == 0);
          kpIndex = min(max(kpIndex, 0) + isSnowy * 4, 9);

	//Total visibility of aurora based on multiple factors
	float visibility = pow6(moonVisibility) * (1.0 - wetness) * caveFactor * (1.0 - pc) * pow2(1.0 - vc);

	//Aurora tends to get brighter and dimmer when plasma arrives or fades away
	float pulse = 0.5 + 0.5 * sin(frameTimeCounter * 0.08 + sin(frameTimeCounter * 0.013) * 0.6);
		  pulse = smoothstep(0.15, 0.85, pulse);

	float longPulse = sin(frameTimeCounter * 0.025 + sin(frameTimeCounter * 0.004) * 0.8);
		  longPulse = longPulse * (1.0 - 0.15 * abs(longPulse));

	kpIndex = 9;
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

        float northSouthStretching = 2.0;
		float eastWestStretching = 1.0;

		for (int i = 0; i < samples; i++) {
			vec3 planeCoord = worldPos * ((10.0 + pow(clamp(VoU, 0.0, 1.0), 0.25) * 15.0 - pulse * 5.0 + currentStep * (10.0 + kpIndex * 5.0) - altitudeFactor) / worldPos.y) * 0.05;
			vec2 coord = planeCoord.xz + cameraPosition.xz * 0.0001;

			//We don'frameTimeCounter want the aurora to render infintely, we also want it to be closer to the north when Kp is low
			float auroraNorthBias = clamp((-planeCoord.x * 0.5 - planeCoord.z) * 0.25 + pow4(kpIndex) * 2.0, 0.0, 1.0);
			float auroraDistanceFactor = clamp(1.0 - length(planeCoord.xz) * 0.1, 0.0, 1.0) * auroraNorthBias;

			if (auroraDistanceFactor > 0.0) {
				coord.y *= 0.35;
                float totalNoise = auroraDistortedNoise(coord * 0.025, pulse, longPulse, kpIndex);

                vec3 lowA = vec3(0.45, 1.55, 0.0);
                vec3 upA = vec3(0.95 + pow3(kpIndex) * pulse, 0.10, 1.05);
                vec3 auroraA = fmix(lowA, upA, pow(currentStep, 0.65)) * exp2(-4.0 * i * sampleStep);

				aurora += auroraA * totalNoise * sqrt(auroraDistanceFactor);
			}
			currentStep += sampleStep;
		}

		color += aurora * visibility * sampleStep;
	}
}