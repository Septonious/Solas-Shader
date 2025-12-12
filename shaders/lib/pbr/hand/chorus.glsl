else if (heldItemId == 80 || heldItemId2 == 80) {
    emission = lAlbedo * float(albedo.r - albedo.b > -0.1 && albedo.g > 0.4) * 0.125;
}