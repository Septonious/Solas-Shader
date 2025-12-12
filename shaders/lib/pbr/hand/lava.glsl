else if (heldItemId == 12 || heldItemId2 == 12) {
    emission = pow3(lAlbedo) * float(albedo.r > 0.5 && albedo.b < 0.4);
}