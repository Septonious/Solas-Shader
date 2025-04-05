float samplePlanarCloudNoise(in vec2 coord) {
    float noise = texture2D(noisetex, coord * 0.0625).r * 15.0;
          noise = mix(noise, texture2D(noisetex, coord).r * 2.0, 0.33);
          noise = max(noise - 6.0, 0.0);
          noise /= sqrt(noise * noise + 0.25);
          noise = clamp(noise, 0.0, 1.0);
    return noise;
}

void drawPlanarClouds(inout vec3 color, in vec3 atmosphereColor, in vec3 worldPos, in vec3 viewPos, in float VoU, in float caveFactor, in float volumetricClouds, inout float pc) {
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

    float VoL = clamp(dot(normalize(viewPos), lightVec), 0.0, 1.0) * shadowFade;
    float cloudHeightFactor = pow2(max(1.0 - 0.00025 * cameraPosition.y, 0.0));

    //Sampling
	vec3 planeCoord = worldPos * (cloudHeightFactor / worldPos.y) * 0.2;

	if (2.0 > length(planeCoord.xz)) {
		 planeCoord.x *= 2.00;
         planeCoord.z *= 0.75;
		vec2 coord = cameraPosition.xz * 0.0001 + planeCoord.xz + frameTimeCounter * 0.001;
		float noise = samplePlanarCloudNoise(coord);
		float noiseL = samplePlanarCloudNoise(coord + normalize(ToWorld(lightVec * 1000000.0)).xz);

		//Lighting and coloring
		#ifdef AURORA
		float visibilityMultiplier = pow8(1.0 - sunVisibility) * (1.0 - wetness) * caveFactor * AURORA_BRIGHTNESS;
		float auroraVisibility = 0.0;

		#ifdef AURORA_FULL_MOON_VISIBILITY
		auroraVisibility = mix(auroraVisibility, 1.0, float(moonPhase == 0));
		#endif

		#ifdef AURORA_COLD_BIOME_VISIBILITY
		auroraVisibility = mix(auroraVisibility, 1.0, isSnowy);
		#endif

		#ifdef AURORA_ALWAYS_VISIBLE
		auroraVisibility = 1.0;
		#endif

		auroraVisibility *= visibilityMultiplier;
		#endif

		pc = noise * pow(VoU, 1.25) * (1.0 - wetness) * (1.0 - volumetricClouds) * caveFactor;

		float cloudLighting = (noiseL - noise * 0.5) * shadowFade * noise;

		vec3 cloudAmbientColor = mix(ambientCol, atmosphereColor * atmosphereColor, 0.5 * sunVisibility);
			 cloudAmbientColor *= 0.25 + sunVisibility * sunVisibility * (0.2 - wetness * 0.2);
		vec3 cloudLightColor = mix(lightCol, mix(lightCol, atmosphereColor, 0.5 * sunVisibility) * atmosphereColor * 2.0, sunVisibility * (1.0 - timeBrightness * 0.33));
			 cloudLightColor *= 1.0 + pow24(VoL) * 2.0;

		vec3 cloudColor = mix(cloudLightColor, cloudAmbientColor, cloudLighting);
			 cloudColor = pow(cloudColor, vec3(1.0 / 2.2));
			 #ifdef AURORA
			 cloudColor = mix(cloudColor, vec3(0.4, 2.5, 0.9) * auroraVisibility, auroraVisibility * 0.05);
			 #endif

		color = mix(color, cloudColor * PLANAR_CLOUDS_BRIGHTNESS, pc * PLANAR_CLOUDS_OPACITY);
	}
}