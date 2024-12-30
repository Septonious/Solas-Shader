if (mat == 106) {
    emission = float(albedo.r > 0.5 && albedo.g < 0.55) * 1.1;
    lightmap.x *= emission;
}