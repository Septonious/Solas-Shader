if (material >= 35 && material <= 40) {
	if (albedo.r + albedo.g + albedo.b < 2.9) {
		if (albedo.b > albedo.g || albedo.r > albedo.g) {
			emission = lAlbedo;
		}
	}
	if (material == 39 && lAlbedo > 0.99) {
		emission = lAlbedo * lAlbedo;
	}

	emission = max(emission, 0.0);

	#ifdef OVERWORLD
	emission *= mix(0.1, 0.0, wetness);
	#endif	
}