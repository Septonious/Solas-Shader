
vec2 getDistortedCoord(in vec2 coord, in float wind, in float strength) {
    float distortX = texture2D(noisetex, coord * 0.1 + vec2(0.0, wind * 0.001)).r;
		  distortX = max(distortX - 0.125, 0.0);
    float distortY = texture2D(noisetex, coord * 0.1 + vec2(5.2, 1.3 + wind * 0.002)).r;
		  distortY = max(distortY - 0.125, 0.0);
	vec2 offset = vec2(distortX, distortY) * 2.0 - 1.0;
		 offset.y *= 2.0;
	return coord + offset * strength;
}
float auroraDistortedNoise(
    sampler2D noiseTex,
    vec2 uv,
    float time,
    float strength
) {
    // Slow upward motion
    vec2 flowUV = uv + vec2(0.0, time * 0.01);

    // First noise sample – used as distortion
    float distortX = texture(noiseTex, flowUV).r;
	distortX = max(distortX - 0.125, 0.0);
    float distortY = texture(noiseTex, flowUV + vec2(5.2, 1.3)).r;
	distortY = max(distortY - 0.125, 0.0);

    // Convert scalar noise to signed vector
    vec2 distortion = vec2(distortX, distortY) * 2.0 - 1.0;

    // Stretch distortion vertically for aurora streaks
    distortion.y *= 3.0;

    // Apply distortion
    vec2 warpedUV = uv + distortion * strength;

    // Final noise sample
    float result = texture(noiseTex, warpedUV).r;
		  result = clamp((result * result - 0.15) * 2.0, 0.0, 1.0);

    return result;
}
void drawAurora(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor, in float vc, in float pc) {
	//The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
    float kpIndex = abs(worldDay % 9 - worldDay % 4);
          kpIndex = kpIndex - int(kpIndex == 1) + int(kpIndex > 7 && worldDay % 10 == 0);
          kpIndex = min(max(kpIndex, 0) + isSnowy * 4, 9);

	//Total visibility of aurora based on multiple factors
	float visibility = pow6(moonVisibility) * (1.0 - wetness) * caveFactor * (1.0 - pc * 0.5) * pow2(1.0 - vc);

	//Aurora tends to get brighter and dimmer when plasma arrives or fades away
    float pulse = clamp(cos(sin(frameTimeCounter * 0.1) * 0.3 + frameTimeCounter * 0.07), 0.0, 1.0);
    float longPulse = clamp(sin(cos(frameTimeCounter * 0.01) * 0.6 + frameTimeCounter * 0.04), -1.0, 1.0);

	kpIndex *= 1.0 + longPulse * 0.25;
	kpIndex = 9;
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
		float tiltFactor = 0.1 + kpIndex * 0.15;
		worldPos.xz += worldPos.y * vec2(tiltFactor * (0.75 + pulse * 0.25), tiltFactor * (2.0 - longPulse));
		//Altitude factor. Makes the aurora closer to you when you're ascending
		float altitudeFactor = clamp(cameraPosition.y * 0.005, 0.0, 24.0);

        float accumulatedNoise = 0.0;
        float northSouthStretching = 0.5;

		for (int i = 0; i < samples; i++) {
			vec3 planeCoord = worldPos * ((5.0 + pow(clamp(VoU, 0.0, 1.0), 0.25) * 20.0 + currentStep * (14.0 + kpIndex * 5.0) - altitudeFactor) / worldPos.y) * 0.05;
			vec2 offsetNoiseCoord = planeCoord.xz + cameraPosition.xz * 0.00005;
			float offsetNoise = texture2D(noisetex, (offsetNoiseCoord + frameTimeCounter * 0.0001) * 0.025).r;
				  offsetNoise = max(offsetNoise - 0.5, 0.0);
				 planeCoord *= 0.5 + offsetNoise;
			vec2 coord = planeCoord.xz + cameraPosition.xz * 0.0001;

			//We don't want the aurora to render infintely, we also want it to be closer to the north when Kp is low
			float auroraNorthBias = clamp((-planeCoord.x * 0.5 - planeCoord.z) * 0.25 * (10.0 - min(kpIndex, 1.0) * 9.0), pow5(kpIndex), 1.0);
			float auroraDistanceFactor = clamp(1.0 - length(planeCoord.xz) * 0.1, 0.0, 1.0) * auroraNorthBias;

			if (auroraDistanceFactor > 0.0) {

                coord.y *= northSouthStretching;
                float stripesOctave = auroraDistortedNoise(noisetex, coord * 0.01, frameTimeCounter * 0.01, 0.25);
                coord.y /= northSouthStretching;

				float arcNoise = stripesOctave;
                float totalNoise = arcNoise;

                vec3 lowA = vec3(0.05, 1.55, 0.40);
                vec3 upA = vec3(0.65, 0.30, 1.05);
                vec3 auroraA = fmix(lowA, upA, pow(currentStep, 0.75 - kpIndex * 0.25)) * exp2(-5.0 * i * sampleStep);

				aurora += auroraA * totalNoise * sqrt(auroraDistanceFactor);
			}
			currentStep += sampleStep;
		}

		color += aurora * visibility * sampleStep;
	}
}