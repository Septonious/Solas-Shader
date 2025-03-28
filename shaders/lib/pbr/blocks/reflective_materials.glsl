else if (material2 == 301) {// Iron, Gold, Emerald, Diamond, Copper & Plates
    smoothness = pow2(lAlbedo) * 0.7;
} else if (material2 == 299) {
    smoothness = pow3(lAlbedo) * 0.65;
    subsurface = 0.6;
}