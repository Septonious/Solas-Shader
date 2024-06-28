if (material >= 32 && material <= 34) {
    emission = lAlbedo * 0.25;
    albedo.rgb = pow(albedo.rgb, vec3(1.75)) * 0.75;
}