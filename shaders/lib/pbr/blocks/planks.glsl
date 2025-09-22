else if (material2 == 314) {// Other Planks
    smoothness = 0.07 * pow3(lAlbedo);
} else if (material2 == 315) {// Dark Oak & Spruce Planks
    smoothness = 0.09 * lAlbedo * lAlbedo;
}