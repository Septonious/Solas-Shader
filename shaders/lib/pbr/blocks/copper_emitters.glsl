else if (material == 83 || material == 84) {
    emission = float(albedo.r - albedo.b < 0.1 && albedo.g > 0.5 && material == 83);
    emission += float(albedo.r - albedo.b < 0.1 && albedo.b * 1.1 - albedo.g - albedo.r < -0.45 && albedo.g > 0.5 && material == 84) * float(NoU > -0.5 && NoU < 0.5);
    emission *= lAlbedo * 0.33;
}