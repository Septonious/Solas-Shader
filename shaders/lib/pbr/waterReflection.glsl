void getReflection(inout vec4 albedo, in vec3 worldPos, in vec3 viewPos, in vec3 nViewPos, in vec3 normal, in float fresnel, in float skyLightMap) {
	float border = 0.0;
	float dither = Bayer8(gl_FragCoord.xy);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

	#if WATER_NORMALS > 0
	vec4 reflectPos = rayTrace(depthtex1, viewPos, normal, dither, fresnel, border, 6, 10, 0.1, 2.0);
	#else
	vec4 reflectPos = rayTrace(depthtex1, viewPos, normal, dither, fresnel, border, 6, 30, 0.1, 2.0);
	#endif

	border = clamp(13.333 * (1.0 - border), 0.0, 1.0);

	vec4 reflection = texture2D(gaux3, reflectPos.xy);
	     reflection.rgb = pow8(reflection.rgb) * 256.0;
         reflection.rgb *= float(reflection.a > 0.0);
		 reflection.a *= border;

	#ifdef OVERWORLD
	vec3 falloff = albedo.rgb;
	#elif defined NETHER
	vec3 falloff = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 falloff = endLightCol * 0.15;
	#endif

	if (reflection.a < 1.0) {
		if (skyLightMap > 0.0) {
			#ifdef OVERWORLD
			vec3 skyRefPos = reflect(normalize(viewPos), normal);
			vec3 worldPosRef = ToWorld(skyRefPos);
			vec3 sunPos = vec3(gbufferModelViewInverse * vec4(sunVec * 128.0, 1.0));
			vec3 sunCoord = sunPos / (sunPos.y + length(sunPos.xz));
			falloff = getAtmosphericScattering(skyRefPos, normalize(sunCoord));

			vec3 stars = vec3(0.0);
			float nebulaFactor = 0.0;

			float VoU = dot(skyRefPos, upVec);
			float VoS = clamp(dot(skyRefPos, sunVec), 0.0, 1.0);

			#ifdef MILKY_WAY
			drawMilkyWay(falloff, worldPosRef, VoU, caveFactor, nebulaFactor, 0.0);
			#endif

			#ifdef STARS
			drawStars(falloff, worldPosRef, sunVec, stars, VoU, VoS, caveFactor, nebulaFactor, 0.0, 0.5);
			#endif
			#endif
		}

		#if MC_VERSION >= 11900
		falloff *= 1.0 - darknessFactor;
		#endif

		falloff *= 1.0 - blindFactor;

		#ifdef OVERWORLD
		falloff = mix(albedo.rgb, falloff, skyLightMap);
		#endif
	}

	vec3 finalReflection = max(mix(falloff, reflection.rgb, reflection.a), vec3(0.0));

	albedo.rgb = mix(albedo.rgb, finalReflection, fresnel * 0.8);
}