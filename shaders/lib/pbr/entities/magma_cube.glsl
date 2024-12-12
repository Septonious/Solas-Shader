if (mat == 103) {
    emission = 0.5 + float(albedo.g > 0.5 && lAlbedo > 0.5) * 0.5;
    lightmap.x *= emission;
}