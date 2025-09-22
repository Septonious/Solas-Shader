else if (material == 80) {
    emission = lAlbedo * float(albedo.r - albedo.b > 0.0 && albedo.g > 0.4) * 0.125;

    #if defined END && MC_VERSION >= 12100
    emission *= 1.0 + endFlashIntensity * 9.0;
    #endif
}