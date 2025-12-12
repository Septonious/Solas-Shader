else if (currentRenderedItemId == 10022 || currentRenderedItemId == 10024 ||currentRenderedItemId == 10025 || currentRenderedItemId == 10026 || currentRenderedItemId == 10027) {
	float isOreEmissive = 0.0;

	#ifdef EMISSIVE_EMERALD_ORE
	isOreEmissive += float(currentRenderedItemId == 10022);
	#endif

	#ifdef EMISSIVE_DIAMOND_ORE
	isOreEmissive += float(currentRenderedItemId == 10023);
	#endif

	#ifdef EMISSIVE_COPPER_ORE
	isOreEmissive += float(currentRenderedItemId == 10024);
	#endif

	#ifdef EMISSIVE_LAPIS_ORE
	isOreEmissive += float(currentRenderedItemId == 10025);
	#endif

	#ifdef EMISSIVE_GOLD_ORE
	isOreEmissive += float(currentRenderedItemId == 10026);
	#endif

	#ifdef EMISSIVE_IRON_ORE
	isOreEmissive += float(currentRenderedItemId == 10027);
	#endif

	#ifdef EMISSIVE_REDSTONE_ORE
	isOreEmissive += float(currentRenderedItemId == 10028);
	#endif

	if (isOreEmissive > 0.5) {
		emission = clamp(max(max(max(albedo.r - albedo.b, albedo.r - albedo.g), max(albedo.b - albedo.g, albedo.b - albedo.r)), max(albedo.g - albedo.r, albedo.g - albedo.b)), 0.0, 1.0);
		emission = clamp(emission * int(emission > 0.1) * 16.0, 0.0, 1.0) * lAlbedo * 0.2;
	}
}
#ifdef EMISSIVE_DIAMOND_ORE 
else if (currentRenderedItemId == 10023) {
	emission = clamp(max(max(max(albedo.r - albedo.b, albedo.r - albedo.g), max(albedo.b - albedo.g, albedo.b - albedo.r)), max(albedo.g - albedo.r, albedo.g - albedo.b)), 0.0, 1.0);
	emission -= int((albedo.r < 0.56 && albedo.g < 0.69 && albedo.b < 0.7) && (albedo.r > 0.54 && albedo.g > 0.67 && albedo.b > 0.68));
	emission -= int((albedo.r < 0.4 && albedo.g < 0.55 && albedo.b < 0.56) && (albedo.r > 0.38 && albedo.g > 0.53 && albedo.b > 0.54));
	emission = clamp(emission * int(emission > 0.1) * 16.0, 0.0, 1.0) * lAlbedo * 0.2;
}
#endif
else if (currentRenderedItemId == 10072) {
	emission = clamp(max(max(max(albedo.r - albedo.b, albedo.r - albedo.g), max(albedo.b - albedo.g, albedo.b - albedo.r)), max(albedo.g - albedo.r, albedo.g - albedo.b)), 0.0, 1.0);
	emission = clamp(emission * int(emission > 0.021) * 16.0, 0.0, 1.0) * lAlbedo * 0.2;
}