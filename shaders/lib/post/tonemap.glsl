vec3 Uncharted2Tonemap(vec3 x) {
    const float A = TONEMAP_HIGHLIGHTS;
    const float B = 0.29;
    const float C = TONEMAP_SHADOWS;
    const float D = 0.15;
    float E = 0.01 * TONEMAP_CONTRAST;
    const float F = 0.35;

	return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}