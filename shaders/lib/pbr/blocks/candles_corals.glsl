else if (material >= 43 && material <= 59) {
    emission = lAlbedo * 0.25;
    if (material == 56) {
        emission *= float(albedo.r - albedo.g < 0.11);
    }
}