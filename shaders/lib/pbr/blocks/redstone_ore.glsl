else if (material == 28 || material == 29) {
    emission = int(albedo.b < 0.3 && albedo.g < 0.3 && albedo.r > 0.4 || albedo.r > 0.7 && albedo.b < 0.7 || albedo.r > 0.99 && albedo.g > 0.99 && albedo.b > 0.99);
    emission -= float((albedo.r < 0.76 && albedo.g < 0.59 && albedo.b < 0.59) && (albedo.r > 0.74 && albedo.g > 0.56 && albedo.b > 0.56));
    emission -= float((albedo.r < 0.78 && albedo.g < 0.73 && albedo.b < 0.67) && (albedo.r > 0.76 && albedo.g > 0.71 && albedo.b > 0.65));
}