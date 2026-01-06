float samplePlanarCloudNoise(in vec2 coord) {
    float noise = texture2D(noisetex, coord * 0.0625).r * 15.0;
          noise = mix(noise, texture2D(noisetex, coord).r * 2.0, 0.33);
          noise = max(noise - PLANAR_CLOUDS_AMOUNT, 0.0);
          noise /= sqrt(noise * noise + 0.25);
          noise = clamp(noise, 0.0, 1.0);
    return noise;
}

void drawPlanarClouds(inout vec3 color, in vec3 atmosphereColor, in vec3 worldPos, in vec3 viewPos, in float VoU, in float caveFactor, in float volumetricClouds, inout float occlusion) {
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

    float cloudHeightFactor = pow2(max(1.0 - 0.0005 * cameraPosition.y, 0.0));

    //Sampling
	vec3 planeCoord = worldPos * (cloudHeightFactor / worldPos.y) * PLANAR_CLOUDS_HEIGHT * 0.001;

	if (length(planeCoord.xz) < 6.0) {
		 planeCoord.x *= 2.00;
         planeCoord.z *= 0.75;
		vec2 coord = cameraPosition.xz * 0.00025 + planeCoord.xz * 1.25 + frameTimeCounter * 0.002;
		vec3 worldLightVec = normalize(ToWorld(lightVec * 100000000.0));
		float noise = samplePlanarCloudNoise(coord);
		float lightingNoise = samplePlanarCloudNoise(coord + worldLightVec.xz * 0.025);

		//Lighting and coloring
		float cloudSample = noise * (1.0 - wetness);
		float pc = cloudSample * pow2(1.0 - volumetricClouds) * caveFactor * VoU;

        float noiseDiff = clamp(noise - lightingNoise * 0.9, 0.0, 1.0);
		float cloudLighting = noiseDiff * shadowFade * 6.0;
			  cloudLighting = clamp(cloudLighting * 0.5 + noise * 0.5, 0.0, 1.0);

		float VoL = dot(normalize(viewPos), lightVec);

		float halfVoL = fmix(abs(VoL) * 0.8, VoL, shadowFade) * 0.5 + 0.5;
		float scattering = pow12(halfVoL);

		vec3 nSkyColor = normalize(skyColor + 0.0001);
		vec3 cloudLightColor = fmix(lightCol, lightCol * nSkyColor * 2.0, timeBrightnessSqrt * (0.5 - wetness * 0.5));
			 cloudLightColor *= 0.5 + timeBrightnessSqrt * 0.5 + moonVisibility * 0.5 + 2.0 * scattering;

		vec3 cloudColor = cloudLightColor * (0.2 + cloudLighting * 0.8) * noise;
			 cloudColor = pow(cloudColor, vec3(1.0 / 2.2));

		#ifdef AURORA_LIGHTING_INFLUENCE
		//The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
		float kpIndex = abs(worldDay % 9 - worldDay % 4);
			  kpIndex = kpIndex - int(kpIndex == 1) + int(kpIndex > 7 && worldDay % 10 == 0);
			  kpIndex = min(max(kpIndex, 0) + isSnowy * 4, 9);

		//Total visibility of aurora based on multiple factors
		float auroraVisibility = pow6(moonVisibility) * (1.0 - wetness) * caveFactor;

		//Aurora tends to get brighter and dimmer when plasma arrives or fades away
        float pulse = 0.5 + 0.5 * sin(frameTimeCounter * 0.08 + sin(frameTimeCounter * 0.013) * 0.6);
              pulse = smoothstep(0.15, 0.85, pulse);

        float longPulse = sin(frameTimeCounter * 0.025 + sin(frameTimeCounter * 0.004) * 0.8);
              longPulse = longPulse * (1.0 - 0.15 * abs(longPulse));

		kpIndex *= 1.0 + longPulse * 0.25;
		kpIndex /= 9.0;
		auroraVisibility *= kpIndex * 0.33;
        cloudColor.r *= 1.0 + 2.0 * pow3(kpIndex) * pulse * auroraVisibility;
        cloudColor.g *= 1.0 + kpIndex * auroraVisibility;
		#endif

		color = fmix(color, cloudColor * PLANAR_CLOUDS_BRIGHTNESS, pc * PLANAR_CLOUDS_OPACITY);
		occlusion += min(cloudSample * cloudSample, 1.0);
	}
}