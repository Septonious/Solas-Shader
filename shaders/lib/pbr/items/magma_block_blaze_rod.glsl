else if (currentRenderedItemId == 21 || currentRenderedItemId == 10021) {
    emission = int(albedo.r > 0.4 && lAlbedo > 0.4) * lAlbedo * 0.25;
}