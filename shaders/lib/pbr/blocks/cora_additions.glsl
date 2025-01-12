if (material == 80 || material == 81) {
    emission = float(albedo.r > albedo.b + albedo.g) * lAlbedo * 0.5;
    albedo.rgb = pow(albedo.rgb, vec3(1.4)) * 0.9;
}

if (material == 82) {
    emission = float((albedo.g > (albedo.r + albedo.b) * 0.75) || (albedo.r > 0.6 && albedo.g > 0.6 && albedo.b > 0.6)) * lAlbedo * 0.5;
    albedo.rgb = pow(albedo.rgb, vec3(1.4)) * 0.9;
}

if (material ==83) {
    emission = float(albedo.b > albedo.r + albedo.g) * lAlbedo * 0.3;
    albedo.rgb = pow(albedo.rgb, vec3(1.4)) * 0.9;
}

if (material == 84 || material == 91) {
    emission = lAlbedo * 0.5;
    albedo.rgb = pow(albedo.rgb, vec3(1.75)) * 0.75;
}

if (material >= 86 && material <= 89) {
    emission = lAlbedo * 0.9;
    albedo.rgb = pow(albedo.rgb, vec3(1.75)) * 0.75;
}

if (material == 85) {
    emission = pow4(lAlbedo) * 0.5;
}

if (material == 90) {
    emission = float((albedo.r > (albedo.g + albedo.b) * 0.7) || (albedo.g > (albedo.r + albedo.b) * 0.7) || (albedo.b > (albedo.g + albedo.r) * 0.7)) * lAlbedo * 0.6;
    albedo.rgb = pow(albedo.rgb, vec3(1.3)) * 0.9;
}