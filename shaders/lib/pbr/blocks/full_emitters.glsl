else if (material >= 7 && material < 12 && material != 10 || material == 31) {
    emission = lAlbedo * lAlbedo * 0.5;
    if (material == 11) smoothness = (0.3 + lAlbedo) * (1.0 - emission);
} else if (material == 12) {
    emission = pow3(lAlbedo) * float(lAlbedo > 0.7);
}