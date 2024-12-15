if (material >= 35 && material <= 40) {
	if (albedo.r + albedo.g + albedo.b < 2.9) {
		if (albedo.b > albedo.g || albedo.r > albedo.g) {
			emission = lAlbedo * 0.1;
			#ifdef OVERWORLD
			emission *= mix(1.0, 0.0, wetness);
			#endif
		}
	}
	if (material == 39 && lAlbedo > 0.99) {
		emission = lAlbedo * lAlbedo * 0.1;
		#ifdef OVERWORLD
		emission *= mix(1.0, 0.0, wetness);
		#endif
	}
}

if (material >= 74 && material <= 79) {
	if (albedo.r + albedo.g + albedo.b < 2.9) {
		if (albedo.b > albedo.g || albedo.r > albedo.g) {
			emission = lAlbedo * 0.1 * (float(lAlbedo > 0.63) * (float(albedo.r + albedo.g * 0.5 + albedo.b * 0.5 > 0.9) + float(albedo.r - albedo.g - albedo.b > 0.3)));
			#ifdef OVERWORLD
			emission *= mix(1.0, 0.0, wetness);
			#endif
		}
	}
}