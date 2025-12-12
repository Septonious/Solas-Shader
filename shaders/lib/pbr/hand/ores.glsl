else if ((heldItemId == 22 || heldItemId == 24 || heldItemId == 25 || heldItemId == 26 || heldItemId == 27) || (heldItemId2 == 22 || heldItemId2 == 24 || heldItemId2 == 25 || heldItemId2 == 26 || heldItemId2 == 27)) {
	float isOreEmissive = 0.0;

	#ifdef EMISSIVE_EMERALD_ORE
	isOreEmissive += float(heldItemId == 22 || heldItemId2 == 22);
	#endif

	#ifdef EMISSIVE_DIAMOND_ORE
	isOreEmissive += float(heldItemId == 23 || heldItemId2 == 23);
	#endif

	#ifdef EMISSIVE_COPPER_ORE
	isOreEmissive += float(heldItemId == 24 || heldItemId2 == 24);
	#endif

	#ifdef EMISSIVE_LAPIS_ORE
	isOreEmissive += float(heldItemId == 25 || heldItemId2 == 25);
	#endif

	#ifdef EMISSIVE_GOLD_ORE
	isOreEmissive += float(heldItemId == 26 || heldItemId2 == 26);
	#endif

	#ifdef EMISSIVE_IRON_ORE
	isOreEmissive += float(heldItemId == 27 || heldItemId2 == 27);
	#endif

	#ifdef EMISSIVE_REDSTONE_ORE
	isOreEmissive += float(heldItemId == 28 || heldItemId2 == 28);
	#endif

	if (isOreEmissive > 0.5) {
		emission = clamp(max(max(max(albedo.r - albedo.b, albedo.r - albedo.g), max(albedo.b - albedo.g, albedo.b - albedo.r)), max(albedo.g - albedo.r, albedo.g - albedo.b)), 0.0, 1.0);
		emission = clamp(emission * int(emission > 0.1) * 16.0, 0.0, 1.0) * lAlbedo * 0.1;
	}
}
#ifdef EMISSIVE_DIAMOND_ORE 
else if (heldItemId == 23 || heldItemId2 == 23) {
	emission = clamp(max(max(max(albedo.r - albedo.b, albedo.r - albedo.g), max(albedo.b - albedo.g, albedo.b - albedo.r)), max(albedo.g - albedo.r, albedo.g - albedo.b)), 0.0, 1.0);
	emission -= int((albedo.r < 0.56 && albedo.g < 0.69 && albedo.b < 0.7) && (albedo.r > 0.54 && albedo.g > 0.67 && albedo.b > 0.68));
	emission -= int((albedo.r < 0.4 && albedo.g < 0.55 && albedo.b < 0.56) && (albedo.r > 0.38 && albedo.g > 0.53 && albedo.b > 0.54));
	emission = clamp(emission * int(emission > 0.1) * 16.0, 0.0, 1.0) * lAlbedo * 0.1;
}
#endif
else if (heldItemId == 72 || heldItemId2 == 72) {
	emission = clamp(max(max(max(albedo.r - albedo.b, albedo.r - albedo.g), max(albedo.b - albedo.g, albedo.b - albedo.r)), max(albedo.g - albedo.r, albedo.g - albedo.b)), 0.0, 1.0);
	emission = clamp(emission * int(emission > 0.021) * 16.0, 0.0, 1.0) * lAlbedo * 0.1;
}