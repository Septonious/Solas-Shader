if (material >= 35 && material <= 40) {
	if (albedo.b > albedo.g || albedo.r > albedo.g) {
		emission = lAlbedo;
		emission = max(emission, 0.0);
	}
    if (material == 39 && albedo.g - albedo.r < 0.2) {
        emission = int(lAlbedo > 0.9);
    }
	#ifdef OVERWORLD
	emission *= mix(0.125, 0.0, wetness);
	#endif	
}