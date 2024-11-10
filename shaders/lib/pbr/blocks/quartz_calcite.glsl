if (material2 == 309) {//Quartz & Calcite
    smoothness = clamp(0.01 + pow32(lAlbedo) * 0.3, 0.0, 0.7);
}