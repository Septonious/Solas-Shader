float auroraDistortedNoise(vec2 coord, float VoU, float kpIndex, float pulse, float longPulse) {
    float t = frameTimeCounter * 0.125;

    vec2 distortedCoord = coord;

    // Soft global rotation (breaks axis lock)
    float baseAngle = (t * 0.0004) * 0.3;
    mat2 baseRot = mat2(cos(baseAngle), -sin(baseAngle),
                        sin(baseAngle),  cos(baseAngle));
    distortedCoord = baseRot * distortedCoord;

    //Low freq distort
    vec2 flowUV = distortedCoord * 0.35;
    flowUV += vec2(
        sin(t * 0.0012),
        cos(t * 0.0010)
    );

    float f = texture2D(noisetex, flowUV).r * 2.0 - 1.0;

    //Perpendicular motion = curl approximation
    vec2 curlDir = normalize(vec2(
        cos(f * 6.283 + t * 0.12),
        sin(f * 6.283 + t * 0.12)
    ));

    const float curlStrength = 0.125;
	vec2 warping = curlDir * f;
    distortedCoord += warping * curlStrength;

    //Now apply vertical stretch AFTER distortion
    distortedCoord.y *= 0.75;
	distortedCoord.x *= 1.5;

    //Arc centered near zenith, very wide and persistent with a slight north bias
    float zenithDist = abs(coord.y + 1.0);
    float arc = exp(-3.0 * zenithDist * zenithDist);

    //Slight waviness so it’s not perfectly straight
    arc *= 0.65 + 0.35 * f;

    //Blurry background noise (aka folds)
    float sheet = texture2D(noisetex, vec2(distortedCoord.x * 1.25, distortedCoord.y * 0.5 + frameTimeCounter * 0.0025)).r;

    sheet *= sheet * sheet * 2.0;

    //High frequency noise (aka rays)
    float rays = texture2D(noisetex, vec2(distortedCoord.x * 5.0, distortedCoord.y * 2.0) + vec2(-frameTimeCounter * 0.0015, frameTimeCounter * 0.0025)).r;
    float flashTime = sin(frameTimeCounter + distortedCoord.x * 64.0 + warping.x * 32.0);
          flashTime = smoothstep(0.4, 1.0, flashTime);
    float aurora = sheet * arc * (50.0 + pow8(rays) * 7500.0 + pow12(rays) * flashTime * 100000.0);

    return max(aurora, 0.0);
}

void drawAurora(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor, in float vc, in float pc) {
	//The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
    float kpIndex = abs(worldDay % 9 - worldDay % 4);
          kpIndex = kpIndex - int(kpIndex == 1) + int(kpIndex > 7 && worldDay % 10 == 0);
          kpIndex = min(max(kpIndex, 0) + isSnowy * 4, 9);

	//Total visibility of aurora based on multiple factors
	float visibility = pow6(moonVisibility) * (1.0 - wetness) * caveFactor * (1.0 - pc) * pow3(1.0 - vc * vc);

	//Aurora tends to get brighter and dimmer when plasma arrives or fades away
	float pulse = 0.5 + 0.5 * sin(frameTimeCounter * 0.08 + sin(frameTimeCounter * 0.013) * 0.6);
		  pulse = smoothstep(0.15, 0.85, pulse);

	float longPulse = sin(frameTimeCounter * 0.025 + sin(frameTimeCounter * 0.004) * 0.8);
		  longPulse = longPulse * (1.0 - 0.15 * abs(longPulse));

	kpIndex *= 1.0 + longPulse * 0.25;
	kpIndex /= 9.0;
	visibility *= kpIndex * (1.0 + max(longPulse * 0.5, 0.0));
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
		worldPos.xz -= worldPos.y * vec2(tiltFactor, tiltFactor * 2.0);
		//Altitude factor. Makes the aurora closer to you when you're ascending
		float altitudeFactor = clamp(cameraPosition.y * 0.005, 0.0, 24.0);

        float northSouthStretching = 2.0;
		float eastWestStretching = 1.0;

		for (int i = 0; i < samples; i++) {
			vec3 planeCoord = worldPos * ((10.0 + pow(clamp(VoU, 0.0, 1.0), 0.25) * 15.0 + currentStep * (10.0 + kpIndex * 5.0) - altitudeFactor) / worldPos.y) * 0.05;
			vec2 coord = planeCoord.xz + cameraPosition.xz * 0.0005;

			//We don'frameTimeCounter want the aurora to render infintely, we also want it to be closer to the north when Kp is low
    		float WEhorizon = clamp(pow(1.0 - abs(planeCoord.x * 0.1), 4.0), 0.0, 1.0);
			float auroraNorthBias = clamp((-planeCoord.x * 0.5 - planeCoord.z) * 0.25 + pow4(kpIndex) * 2.0, 0.0, 1.0);
			float auroraDistanceFactor = clamp(1.0 - length(planeCoord.xz) * 0.1, 0.0, 1.0) * auroraNorthBias * WEhorizon;

			if (auroraDistanceFactor > 0.0) {
                float auroraSample = auroraDistortedNoise(coord * 0.025, VoU, kpIndex, pulse, longPulse);

                vec3 lowA = vec3(0.45, 1.55, 0.0);
                vec3 upA = vec3(0.95 + pow3(kpIndex) * pulse, 0.10, 1.05);
                vec3 auroraA = fmix(lowA, upA, pow(currentStep, 0.65 + pow3(kpIndex) * pulse * 0.1)) * exp2(-4.0 * i * sampleStep);

				aurora += auroraA * auroraSample * sqrt(auroraDistanceFactor);
			}
			currentStep += sampleStep;
		}

		color += aurora * visibility * sampleStep;
	}
}