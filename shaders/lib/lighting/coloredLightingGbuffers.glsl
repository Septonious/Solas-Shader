float getLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

const bool gaux1MipmapEnabled = true;
const bool gaux2MipmapEnabled = true;

void applyCLGI(in vec3 blocklightCol, in vec3 screenPos, inout vec3 coloredLighting, inout vec3 globalIllumination, in vec2 lightmap) {
	if (screenPos.z > 0.56) {
		screenPos.xy = Reprojection(screenPos);
	}

	#ifdef COLORED_LIGHTING
	vec3 cl = texture2DLod(gaux1, screenPos.xy, 2).rgb;
	
	vec3 coloredLightNormalized = cl + 0.000001;
		 coloredLightNormalized = normalize(coloredLightNormalized * coloredLightNormalized) * 0.875 + 0.125;
		 coloredLightNormalized *= getLuminance(blocklightCol) * 1.7;
	float coloredLightMix = min((cl.r + cl.g + cl.b) * 1024.0, 1.0);

	coloredLighting = mix(blocklightCol, coloredLightNormalized, coloredLightMix * COLORED_LIGHTING_MIX);
	#endif

	#ifdef GI
	vec3 gi = texture2DLod(gaux2, screenPos.xy, 2).rgb;
	float globalIlluminationMix = min((gi.r + gi.g + gi.b) * 32.0, 1.0);

	globalIllumination = mix(vec3(0.0), normalize(gi + 0.00000001), globalIlluminationMix);
	#endif
}