if (material == 73) {
    emission = float(albedo.r > albedo.b + (albedo.g * 0.5)) * 0.2;
}