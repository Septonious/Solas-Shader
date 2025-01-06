else if (material == 22 || material == 24 ||material == 25 || material == 26 || material == 27) {
	emission = clamp(max(max(max(albedo.r - albedo.b, albedo.r - albedo.g), max(albedo.b - albedo.g, albedo.b - albedo.r)), max(albedo.g - albedo.r, albedo.g - albedo.b)), 0.0, 1.0);
	emission = clamp(emission * int(emission > 0.1) * 16.0, 0.0, 1.0) * lAlbedo * 0.25;
} else if (material == 23) {
	emission = clamp(max(max(max(albedo.r - albedo.b, albedo.r - albedo.g), max(albedo.b - albedo.g, albedo.b - albedo.r)), max(albedo.g - albedo.r, albedo.g - albedo.b)), 0.0, 1.0);
	emission -= int((albedo.r < 0.56 && albedo.g < 0.69 && albedo.b < 0.7) && (albedo.r > 0.54 && albedo.g > 0.67 && albedo.b > 0.68));
	emission -= int((albedo.r < 0.4 && albedo.g < 0.55 && albedo.b < 0.56) && (albedo.r > 0.38 && albedo.g > 0.53 && albedo.b > 0.54));
	emission = clamp(emission * int(emission > 0.1) * 16.0, 0.0, 1.0) * lAlbedo * 0.25;
} else if (material == 72) {
	emission = clamp(max(max(max(albedo.r - albedo.b, albedo.r - albedo.g), max(albedo.b - albedo.g, albedo.b - albedo.r)), max(albedo.g - albedo.r, albedo.g - albedo.b)), 0.0, 1.0);
	emission = clamp(emission * int(emission > 0.021) * 16.0, 0.0, 1.0) * lAlbedo * 0.25;
}