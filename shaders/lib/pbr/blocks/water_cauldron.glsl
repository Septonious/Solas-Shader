
else if (material2 == 311) {// Water cauldron
    if (albedo.b > 0.4 && lAlbedo > 0.5) {
        smoothness = 0.9;
        albedo.rgb = waterColor;
    }
}