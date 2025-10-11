else if (material == 83 || material == 84) {
    emission = float(lAlbedo > 0.95 || (albedo.g > 0.65 && albedo.b < 0.45)) + float((albedo.g > 0.35 && albedo.r < 0.3) && material == 83);
    emission *= lAlbedo * 0.33;
}