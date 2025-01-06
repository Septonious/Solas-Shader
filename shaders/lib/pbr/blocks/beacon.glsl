else if (material == 60) {
    vec3 nAlbedo = pow4(albedo.rgb);
    emission = float(nAlbedo.g > 0.8 || (albedo.b > 0.5 && albedo.r < 0.45)) * 0.5;
}