if (material >= 15 && material <= 20) {
    #ifdef EMISSIVE_CONCRETE    
    emission = lAlbedo;
    #endif

    smoothness = clamp(lAlbedo * 0.06, 0.0, 0.1);
} else if (material2 == 318) {
    smoothness = clamp(lAlbedo * 0.06, 0.0, 0.1);
}