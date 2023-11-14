float getLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

void applyCLGI(in vec3 blocklightCol, in vec3 screenPos, inout vec3 coloredLighting, inout vec3 globalIllumination, in float blockLightMap) {
	vec3 prvScreenPos = screenPos;

	if (screenPos.z > 0.56) {
		prvScreenPos.xy = Reprojection(prvScreenPos);
	}

	#ifdef COLORED_LIGHTING
	vec3 cl = texture2D(gaux1, prvScreenPos.xy).rgb;
	vec3 coloredLightNormalized = normalize(cl + 0.00000001);
	     coloredLightNormalized *= getLuminance(blocklightCol) / getLuminance(coloredLightNormalized);
	float coloredLightMix = min((cl.r + cl.g + cl.b) * 1024.0, 1.0);

	coloredLighting = mix(blocklightCol, coloredLightNormalized, coloredLightMix * COLORED_LIGHTING_MIX * float(length(coloredLightNormalized) > 0.01)) * blockLightMap;
	#endif

	#ifdef GI
	vec3 gi = texture2D(gaux2, prvScreenPos.xy).rgb;
	vec3 globalIlluminationNormalized = normalize(gi + 0.00000001);
	float globalIlluminationMix = min((gi.r + gi.g + gi.b), 1.0);
	      globalIlluminationMix *= 1.0 - min(blockLightMap, 1.0);

	globalIllumination = mix(vec3(0.0), globalIlluminationNormalized, globalIlluminationMix * GLOBAL_ILLUMINATION_STRENGTH * timeBrightness * float(length(globalIlluminationNormalized) > 0.1));
	#endif
}