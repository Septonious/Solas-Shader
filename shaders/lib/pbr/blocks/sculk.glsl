if (material == 61) {
    float noise = texture2D(noisetex, (worldPos.xz + cameraPosition.xz + frameCounter * 0.003) * 0.001).b;
          noise = clamp(noise - 0.25, 0.0, 1.0);
	emission = int(lAlbedo > 0.3 && albedo.r < 0.2 && albedo.b > 0.2) * 0.1 * lAlbedo * noise;
} else if (material == 63) {
    emission = float(albedo.r > 0.35) * 0.125;
}