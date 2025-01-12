if (material == 21) {
    emission = int(albedo.r > 0.7 && lAlbedo > 0.4) * lAlbedo * 0.65;
}