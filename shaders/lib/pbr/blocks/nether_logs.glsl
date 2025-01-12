if (material == 65) {
    emission = lAlbedo * pow6(albedo.r) * (1.0 - pow(albedo.b, 0.2) * 1.2) * 16.0;
} else if (material == 66) {
    emission = lAlbedo * pow3(albedo.b) * (1.0 - min(pow(albedo.r, 0.1) * 1.2, 1.0)) * 32.0;
}