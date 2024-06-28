if (material >= 35 && material <= 40 || (material >= 305 && material <= 312)) {
	if (albedo.b > albedo.g || albedo.r > albedo.g) {
		emission = lAlbedo;
		emission = max(emission, 0.0);
	}
    if (material == 39) {
        emission = int(lAlbedo > 0.9);
    }
	#ifdef OVERWORLD
	emission *= mix(0.075, 0.0, wetness);
	#endif	
}