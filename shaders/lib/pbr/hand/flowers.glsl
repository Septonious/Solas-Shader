else if ((heldItemId >= 35 && heldItemId <= 40) || (heldItemId2 >= 35 && heldItemId2 <= 40)) {
	float emissionFactor = 0.25 * lAlbedo * (0.1 + (1.0 - clamp(length(viewPos) * 0.25, 0.0, 1.0)));
    if (albedo.r + albedo.g + albedo.b < 2.9 && (heldItemId != 39 || heldItemId2 != 39)) {
		if (albedo.b > albedo.g || albedo.r > albedo.g) {
			emission = emissionFactor * (1.0 - float(heldItemId == 36 || heldItemId2 == 36) * 0.5);
            if (heldItemId == 40 || heldItemId2 == 40) {
                emission *= float(albedo.r > 0.6 && albedo.b < 0.3);
            } else if ((heldItemId >= 74 && heldItemId <= 79) || (heldItemId2 >= 74 && heldItemId2 <= 79)) {
                emission *= float(lAlbedo > 0.63) * (float(albedo.r + albedo.g * 0.5 + albedo.b * 0.5 > 0.9) + float(albedo.r - albedo.g - albedo.b > 0.3));
            }
			#ifdef OVERWORLD
			emission *= mix(1.0, 0.0, wetness);
			#endif
		}
    } else if ((heldItemId == 39 || heldItemId2 == 39) && lAlbedo > 0.99) {
        emission = emissionFactor;
        #ifdef OVERWORLD
        emission *= mix(1.0, 0.0, wetness);
        #endif
    }
}