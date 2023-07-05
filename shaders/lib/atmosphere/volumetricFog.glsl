void computeVolumetricFog(inout vec3 vf, in vec3 translucent, in float dither) {
	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	//Positions
	vec3 viewPos = ToView(vec3(texCoord.xy, z0));

	//Total Visibility
	float visibility = 0.005 * int(z0 > 0.56) * (1.0 - float(isEyeInWater == 2));
	#if defined NETHER
	visibility *= VF_NETHER_STRENGTH;
	#elif defined END
	visibility *= VF_END_STRENGTH;
	#endif

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Linear Depths
		float linearDepth0 = getLinearDepth(z0);
		float linearDepth1 = getLinearDepth(z1);

		//Variables
		float distanceFactor = 8.0;
		float lViewPos = length(viewPos);

		//Ray Marching
		#ifdef NETHER
		for (int i = 0; i < VF_NETHER_SAMPLES; i++) {
		#else
		for (int i = 0; i < VF_END_SAMPLES; i++) {
		#endif
			float currentDepth = (i + dither) * distanceFactor;

			if (linearDepth1 < currentDepth || (linearDepth0 < currentDepth && translucent.rgb == vec3(0.0))) {
				break;
			}

			vec3 worldPos = ToWorld(ToView(vec3(texCoord, getLogarithmicDepth(currentDepth))));

			#ifdef NETHER
			if (length(worldPos) > 128.0) break;
			#else
			if (length(worldPos) > 196.0) break;
			#endif

			//Noise
			vec3 fog = vec3(1.0);
			float noise = 1.0;

			if (isEyeInWater == 0) {
				#ifdef NETHER
				vec3 npos = (worldPos + cameraPosition) * VF_NETHER_FREQUENCY + vec3(frameTimeCounter, 0.0, 0.0) * VF_NETHER_SPEED;
				float n3da = texture2D(noisetex, npos.xz * 0.0005 + floor(npos.y * 0.1) * 0.1).r;
				float n3db = texture2D(noisetex, npos.xz * 0.0005 + floor(npos.y * 0.1 + 1.0) * 0.1).r;
				noise = sin(mix(n3da, n3db, fract(npos.y * 0.1)) * 14.0 + frameTimeCounter * 0.01);
				#else
				vec3 npos = worldPos + cameraPosition;
				float sampleHeight = abs(VF_END_HEIGHT - npos.y) / VF_END_THICKNESS;
				npos += vec3(frameTimeCounter, 0.0, 0.0);
				float n3da = texture2D(noisetex, npos.xz * 0.0005 + floor(npos.y * 0.1) * 0.1).r;
				float n3db = texture2D(noisetex, npos.xz * 0.0005 + floor(npos.y * 0.1 + 1.0) * 0.1).r;
				noise = sin(mix(n3da, n3db, fract(npos.y * 0.1)) * 16.0);
				noise = clamp(noise - sampleHeight, 0.0, 1.0);
				#endif
			}

			fog *= noise;

			//Translucency Blending
			if (linearDepth0 < currentDepth) {
				fog *= translucent.rgb;
			}

			vf += fog;
		}

		#ifdef NETHER
		vf *= netherColSqrt;
		#else
		vf *= endLightCol;
		#endif
		vf *= visibility;
	}
}