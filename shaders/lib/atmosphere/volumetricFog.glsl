void computeVolumetricFog(inout vec3 vf, inout vec3 color, in vec3 translucent, in float dither) {
	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	//Positions
	vec3 viewPos = ToView(vec3(texCoord.xy, z0));

	//Total Visibility
	float visibility = 0.005 * int(z0 > 0.56) * (1.0 - float(isEyeInWater == 2));
		  visibility *= VF_NETHER_STRENGTH;

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
		for (int i = 0; i < VF_NETHER_SAMPLES; i++) {
			float currentDepth = (i + dither) * distanceFactor;

			if (linearDepth1 < currentDepth || (linearDepth0 < currentDepth && translucent.rgb == vec3(0.0))) {
				break;
			}

			vec3 worldPos = ToWorld(ToView(vec3(texCoord, getLogarithmicDepth(currentDepth))));

			if (length(worldPos) > 128.0) break;

			//Noise
			vec3 fog = vec3(1.0);
			float noise = 1.0;

			if (isEyeInWater == 0) {
				vec3 npos = vec3(cameraPosition.x + worldPos.x, cameraPosition.y + worldPos.y, cameraPosition.z + worldPos.z) * vec3(VF_NETHER_FREQUENCY, VF_NETHER_FREQUENCY * 0.6, VF_NETHER_FREQUENCY) + vec3(frameTimeCounter, 0.0, 0.0) * VF_NETHER_SPEED;
				float n3da = texture2D(noisetex, npos.xz * 0.0005 + floor(npos.y * 0.1) * 0.1 - frameTimeCounter * VF_NETHER_SPEED * 0.001).r;
				float n3db = texture2D(noisetex, npos.xz * 0.0005 + floor(npos.y * 0.1 + 1.0) * 0.1 - frameTimeCounter * VF_NETHER_SPEED * 0.001).r;
				noise = sin(mix(n3da, n3db, fract(npos.y * 0.1)) * 14.0 + frameTimeCounter * 0.01);
			}

			fog *= noise;

			//Translucency Blending
			if (linearDepth0 < currentDepth) {
				fog *= translucent.rgb;
			}

			vf += fog;
		}

		#ifdef VF_NETHER_REFRACTION
		color = pow(texture2D(colortex0, texCoord + vec2(vf.xy * 0.001 * VF_NETHER_REFRACTION_STRENGTH)).rgb, vec3(2.2));
		#endif

		vf *= netherColSqrt * 2.0;
		vf *= visibility;
	}
}