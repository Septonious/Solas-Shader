vec3 Uncharted2Tonemap(vec3 color) {	
    const float B = 0.350;		
	const float D = 0.150;
	const float F = 0.350;

	return ((color * (LIGHTNESS_INTENSITY * color + DARKNESS_INTENSITY * B) + D * CONTRAST) / (color * (LIGHTNESS_INTENSITY * color + B) + D * F)) - CONTRAST / F;
}