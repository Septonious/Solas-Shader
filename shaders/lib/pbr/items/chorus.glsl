else if (currentRenderedItemId == 10080) {
    emission = lAlbedo * float(albedo.r - albedo.b > -0.1 && albedo.g > 0.4) * 0.125;
}