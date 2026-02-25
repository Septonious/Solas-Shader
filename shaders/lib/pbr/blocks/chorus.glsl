else if (material == 80) {
    emission = lAlbedo * float(albedo.r - albedo.b > 0.0 && albedo.g > 0.4) * 0.125;

    #ifdef END_FLASHES
    emission *= 1.0 + endFlashIntensity * 9.0;
    #endif
}