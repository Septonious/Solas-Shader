else if (currentRenderedItemId >= 10032 && currentRenderedItemId <= 10034) {
    emission = lAlbedo * 0.5;
    albedo.rgb = pow(albedo.rgb, vec3(1.75)) * 0.75;
}