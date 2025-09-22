else if (material >= 43 && material <= 59) {
    emission = pow8(lAlbedo) * 0.05;
    if (material == 56) {
        emission *= float(albedo.r - albedo.g < 0.11);
    }
}