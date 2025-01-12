if (material == 5) {
    emission = int(albedo.r > 0.8 && albedo.g > 0.5 || albedo.r > 0.6 && albedo.b < 0.2);
}