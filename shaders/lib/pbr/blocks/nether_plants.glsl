if (material == 64) {
    emission = int(lAlbedo > 0.9) * 0.25;
} else if (material == 67) {
    emission = pow16(lAlbedo) * 0.25;
} else if (material == 68) {
    emission = pow7(lAlbedo) * 0.35;
}