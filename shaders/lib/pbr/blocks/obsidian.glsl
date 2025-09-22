else if (material2 == 321 || material == 11) {
    smoothness = 0.03 + lAlbedo * 0.15 + lAlbedo * lAlbedo * 0.5;
    if (material == 11) {
        emission = lAlbedo * lAlbedo * 0.5;
    }
}