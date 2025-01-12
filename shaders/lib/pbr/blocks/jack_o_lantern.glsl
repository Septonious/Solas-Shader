if (material == 41) {
    emission = int(pow4(lAlbedo) > 0.99 && albedo.b > 0.3) * 0.5;
}