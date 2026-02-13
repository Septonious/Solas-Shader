float samplePlanarCloudNoise(vec2 coord) {
    float n1 = texture2D(noisetex, coord * 0.0625).r;
    float n2 = texture2D(noisetex, coord).r;

    float noise = fmix(n1 * 15.0, n2 * 2.0, 0.33);

    noise = smoothstep(
        PLANAR_CLOUDS_AMOUNT,
        PLANAR_CLOUDS_AMOUNT + 0.75,
        noise
    );

    noise = noise * noise * (3.0 - 2.0 * noise);

    return clamp(noise, 0.0, 1.0);
}


void drawPlanarClouds(inout vec3 color, in vec3 atmosphereColor, in vec3 worldPos, in vec3 viewPos, in float VoU, in float caveFactor) {
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

    float altitudeFactor = min(max(cameraPosition.y, 0.0) / KARMAN_LINE, 1.0);
    float altitudeFactor10k = min(max(cameraPosition.y, 0.0) * 0.0001, 1.0);
    float cloudHeightFactor = 0.125 + pow2(clamp(1.0 - 0.001 * cameraPosition.y * (0.5 - altitudeFactor), 0.0, 3.5));

    //Sampling
	vec3 planeCoord = worldPos * (cloudHeightFactor / worldPos.y) * PLANAR_CLOUDS_HEIGHT * 0.001;
    float coordLength = length(planeCoord.xz);
    float distanceFactor = clamp(1.0 - coordLength * max(0.15 - altitudeFactor * 0.085 - altitudeFactor10k * (1.0 - altitudeFactor)  * 0.25, 0.005), 0.0, 1.0);
    planeCoord *= 2.0 - distanceFactor;

	if (distanceFactor > 0.0) {
        vec2 warp;
        warp.x = sin(planeCoord.z * 0.5 - frameTimeCounter * 0.001);
        warp.y = cos(planeCoord.x * 0.3 - frameTimeCounter * 0.002);

        planeCoord.xz += warp * 0.5;

		vec2 coord = cameraPosition.xz * 0.00025 * (0.5 - altitudeFactor10k) + planeCoord.xz * 1.25 + frameTimeCounter * 0.005;
		vec3 worldLightVec = normalize(ToWorld(lightVec * 100000000.0));
		float noise = samplePlanarCloudNoise(coord);
		float lightingNoise = samplePlanarCloudNoise(coord + worldLightVec.xz * 0.025);

		//Lighting and coloring
        vec3 nWorldPos = normalize(worldPos);
        float fade = pow(max(nWorldPos.y, 0.0), 0.125);
                fade = mix(fade, (1.0 - fade) * float(nWorldPos.y < 0.0), altitudeFactor10k);
                fade *= pow3(fade);
                fade *= distanceFactor;
		float cloudSample = noise * (1.0 - wetness) * fade;
		float pc = cloudSample * caveFactor;

        float noiseDiff = clamp(noise - lightingNoise, 0.0, 1.0);
		float cloudLighting = (0.25 + noiseDiff * shadowFade * 2.0) * (1.0 - noise * noise * (1.0 - altitudeFactor10k) * 0.75) * 2.0;

		float VoL = dot(normalize(viewPos), lightVec);

		float halfVoL = fmix(abs(VoL) * 0.8, VoL, shadowFade) * 0.5 + 0.5;
		float scattering = pow12(halfVoL);

		vec3 nSkyColor = normalize(skyColor + 0.0001);
		vec3 cloudLightColor = fmix(lightCol, lightCol * nSkyColor * 2.0, timeBrightnessSqrt * (0.5 - wetness * 0.5));
			 cloudLightColor *= 0.25 + sunVisibility * 0.5 + moonVisibility * 0.5 + 2.0 * scattering;

		vec3 cloudColor = cloudLightColor * cloudLighting * noise;
			 cloudColor = pow(cloudColor, vec3(1.0 / 2.2));
             cloudColor = mix( cloudColor, atmosphereColor, 0.4);

		color = fmix(color, cloudColor * PLANAR_CLOUDS_BRIGHTNESS, pc);
	}
}