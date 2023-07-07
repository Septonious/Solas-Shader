float getLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

void applyCLGI(in vec3 blocklightCol, in vec3 screenPos, inout vec3 coloredLighting, inout vec3 globalIllumination, in float giLightMap) {
	if (screenPos.z > 0.56) {
		screenPos.xy = Reprojection(screenPos);
	}

	#ifdef COLORED_LIGHTING
	vec3 cl = texture2D(gaux1, screenPos.xy).rgb;
	vec3 coloredLightNormalized = normalize(cl * cl + 0.00000001);
	     coloredLightNormalized *= getLuminance(blocklightCol) / getLuminance(coloredLightNormalized);
	float coloredLightMix = min((cl.r + cl.g + cl.b) * 128.0, 1.0);

	coloredLighting = mix(blocklightCol, coloredLightNormalized, coloredLightMix * COLORED_LIGHTING_MIX);
	#endif

	#ifdef GLOBAL_ILLUMINATION
	vec3 gi = texture2D(gaux2, screenPos.xy).rgb;
		 gi *= gi * 2.0;

	vec3 giNormalized = normalize(gi + 0.00000001);
	float globalIlluminationMix = min((gi.r + gi.g + gi.b) * 128.0, 1.0);
	float eBS = eyeBrightnessSmooth.y / 240.0;
		  eBS *= eBS;

	//globalIllumination = (clamp(0.0625 * gi * pow(getLuminance(gi), -0.6), 0.0, 1.0) * 16.0 * GLOBAL_ILLUMINATION_STRENGTH_1 + giNormalized * GLOBAL_ILLUMINATION_STRENGTH_2 * (1.0 - eBS * 0.5)) * (1.0 - eBS * 0.5);
	globalIllumination = mix(vec3(0.0), giNormalized * (1.0 - eBS * eBS * 0.75), globalIlluminationMix);
	#endif
}