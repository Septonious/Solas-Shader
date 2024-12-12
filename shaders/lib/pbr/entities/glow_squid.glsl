if (mat == 105) {
    emission = float(albedo.g > albedo.b) * 0.25;
    lightmap.x *= 0.5 + emission;
}