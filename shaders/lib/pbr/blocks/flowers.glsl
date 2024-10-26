if (material >= 35 && material <= 40) {
	if (albedo.b > albedo.g || albedo.r > albedo.g) {
		emission = lAlbedo;
		emission = max(emission, 0.0);
	}

	#ifdef OVERWORLD
	emission *= mix(0.1, 0.0, wetness);
	#endif	
}