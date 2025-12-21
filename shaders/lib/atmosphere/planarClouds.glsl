float samplePlanarCloudNoise(in vec2 coord) {
    float noise = texture2D(noisetex, coord * 0.0625).r * 15.0;
          noise = fmix(noise, texture2D(noisetex, coord).r * 2.0, 0.33);
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
		vec2 coord = cameraPosition.xz * 0.0002 + planeCoord.xz + frameTimeCounter * 0.002;
		float noise = samplePlanarCloudNoise(coord);
		float noiseL = samplePlanarCloudNoise(coord - normalize(ToWorld(lightVec * 1000000.0)).xz * 0.01);

		//Lighting and coloring
		float pc = noise * (1.0 - wetness) * pow2(1.0 - volumetricClouds) * caveFactor;
		pc *= VoU;

		float cloudLighting = (noiseL - noise) * shadowFade * 8.0;
			  cloudLighting = clamp(cloudLighting * 0.5 + noise * 0.5, 0.0, 1.0);

		vec3 nSkyColor = normalize(skyColor + 0.0001);
		vec3 cloudAmbientColor = fmix(atmosphereColor * atmosphereColor * 0.5, 
								 fmix(ambientCol, atmosphereColor * nSkyColor * 0.3, 0.2 + timeBrightnessSqrt * 0.3 + isSpecificBiome * 0.4),
									 sunVisibility * (1.0 - wetness));
		vec3 cloudLightColor = fmix(lightCol, lightCol * nSkyColor * 2.0, timeBrightnessSqrt * (0.5 - wetness * 0.5));
			 cloudLightColor *= 0.5 + timeBrightnessSqrt * 0.5 + moonVisibility * 0.5;

		vec3 cloudColor = cloudLightColor * (0.2 + cloudLighting * 0.8) * noise;
			 cloudColor = pow(cloudColor, vec3(1.0 / 2.2));

		color = fmix(color, cloudColor * PLANAR_CLOUDS_BRIGHTNESS, pc * PLANAR_CLOUDS_OPACITY);
		occlusion += min(pow3(pc) * 3.0, 1.0);
	}
}