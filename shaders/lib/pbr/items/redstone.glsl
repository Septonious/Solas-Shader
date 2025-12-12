else if (currentRenderedItemId == 10028) {
    emission = 0.25 * int(albedo.b < 0.3 && albedo.g < 0.3 && albedo.r > 0.4 || albedo.r > 0.7 && albedo.b < 0.7 || albedo.r > 0.99 && albedo.g > 0.99 && albedo.b > 0.99);
    emission *= 1.0 - float((albedo.r < 0.76 && albedo.g < 0.59 && albedo.b < 0.59) && (albedo.r > 0.74 && albedo.g > 0.56 && albedo.b > 0.56));
} else if (currentRenderedItemId == 10029) {
    emission = float(albedo.r > 0.8) * lAlbedo * 2.0;
}