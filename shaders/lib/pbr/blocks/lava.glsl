else if (material == 12) {
    emission = pow3(lAlbedo) * float(lAlbedo > 0.7);

    if (emission > 0.0) {
        vec2 pos = (worldPos.xz + cameraPosition.xz) * 0.5 + (worldPos.xy + cameraPosition.xy) * 0.5 + (worldPos.zy + cameraPosition.zy) * 0.5;
        pos.x *= 0.5;
        float lavaNoise = clamp(texture2D(noisetex, (pos + vec2(-frameTimeCounter * 0.1, frameTimeCounter * 0.05)) * 0.025).r + 0.3, 0.0, 1.0);
        albedo.rgb = normalize(vec3(LAVA_R, LAVA_G, LAVA_B)) * pow5(lavaNoise) * (3.0 + pow5(lAlbedo) * 2.0);
    }
}