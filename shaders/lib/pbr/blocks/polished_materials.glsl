if (material2 == 302) {// Polished & smooth blocks
    smoothness = clamp(pow9(lAlbedo) * 0.35 + 0.025, 0.0, 0.45);
}