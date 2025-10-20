else if (material == 64 || material == 81 || material == 82) {
    emission = int(lAlbedo > 0.9) * 0.25;
} else if (material == 67) {
    emission = int(lAlbedo > 0.8) * lAlbedo * 0.01;
} else if (material == 68) {
    emission = int(lAlbedo > 0.6) * lAlbedo * 0.01;
}