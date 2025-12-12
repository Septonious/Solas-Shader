else if (currentRenderedItemId >= 10035 && currentRenderedItemId <= 10040) {
	float emissionFactor = 0.25 * lAlbedo * (0.1 + (1.0 - clamp(length(viewPos) * 0.25, 0.0, 1.0)));
    if (albedo.r + albedo.g + albedo.b < 2.9 && currentRenderedItemId != 10039) {
		if (albedo.b > albedo.g || albedo.r > albedo.g) {
			emission = emissionFactor * (1.0 - float(currentRenderedItemId == 10036) * 0.5);
            if (currentRenderedItemId == 10040) {
                emission *= float(albedo.r > 0.6 && albedo.b < 0.3);
            }
			#ifdef OVERWORLD
			emission *= mix(1.0, 0.0, wetness);
			#endif
		}
    } else if (currentRenderedItemId == 10039 && lAlbedo > 0.99) {
        emission = emissionFactor;
        #ifdef OVERWORLD
        emission *= mix(1.0, 0.0, wetness);
        #endif
    }
}