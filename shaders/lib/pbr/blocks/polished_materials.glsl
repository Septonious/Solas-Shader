if (material2 == 302) {// Polished & smooth blocks
    smoothness = clamp(pow3(lAlbedo) * 0.4, 0.1, 0.5);
}