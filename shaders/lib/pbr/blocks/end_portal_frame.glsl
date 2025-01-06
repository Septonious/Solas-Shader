else if (material == 71) {
    lightmap.x *= 0.0;
    emission = float(albedo.r < 0.65 && (lAlbedo > 0.9 && albedo.r > 0.55 || lAlbedo > 0.75) || (albedo.r > 0.7 && albedo.b > 0.7 && (albedo.r - 0.5 * (albedo.g + albedo.b) < 0.0))) * 0.075;
    emission *= 4.0;
}