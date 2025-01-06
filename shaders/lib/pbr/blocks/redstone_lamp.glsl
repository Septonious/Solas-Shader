else if (material == 70) {
    smoothness = float(lAlbedo > 0.3) * 0.33;
} else if (material == 10) {
    emission = clamp((float(albedo.g - albedo.r < 0.25 && albedo.r - albedo.b > 0.485) + float(albedo.r > 0.9 && albedo.r - albedo.g - albedo.b > -1.0)) * 100.0, 0.0, 1.0);
}