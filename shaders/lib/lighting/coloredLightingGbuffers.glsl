float getLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

void applyCLGI(in vec3 blocklightCol, in vec3 screenPos, inout vec3 coloredLighting, inout vec3 globalIllumination, in float blockLightMap) {
	if (screenPos.z > 0.56) {
		screenPos.xy = Reprojection(screenPos);
	}

	float eBS = eyeBrightnessSmooth.y / 240.0;

	#ifdef COLORED_LIGHTING
	vec3 cl = texture2DLod(gaux1, screenPos.xy, 1).rgb;
	vec3 coloredLightNormalized = normalize(cl + 0.00001);
	     coloredLightNormalized *= clamp(getLuminance(blocklightCol) / getLuminance(coloredLightNormalized), 0.0, 16.0);
	float coloredLightMix = clamp((cl.r + cl.g + cl.b) * 1024.0, 0.0, 1.0);

	coloredLighting = mix(blocklightCol, coloredLightNormalized, coloredLightMix * COLORED_LIGHTING_MIX) * blockLightMap;
	#endif

	#ifdef GI
	vec3 gi = texture2DLod(gaux2, screenPos.xy, 0).rgb;
	vec3 globalIlluminationNormalized = normalize(gi + 0.00001);
	float globalIlluminationMix = clamp((gi.r + gi.g + gi.b), 0.0, 1.0);

	globalIllumination = mix(vec3(0.0), globalIlluminationNormalized, globalIlluminationMix * GLOBAL_ILLUMINATION_STRENGTH);
	#endif
}