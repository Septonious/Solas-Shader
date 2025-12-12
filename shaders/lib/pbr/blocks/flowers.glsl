else if ((material >= 35 && material <= 40) || (material >= 305 && material <= 312)) { //Regular flowers
	float emissionFactor = 0.25 * lAlbedo * (0.1 + (1.0 - clamp(length(viewPos) * 0.25, 0.0, 1.0)));
	float noise = texture2D(noisetex, (worldPos.xz + cameraPosition.xz + frameCounter * 0.01) * 0.001).b;
		  noise = 0.75 + clamp(noise - 0.4, 0.0, 1.0);
    if (albedo.r + albedo.g + albedo.b < 2.9 && material != 39) {
		if (albedo.b > albedo.g || albedo.r > albedo.g) {
			emission = emissionFactor * noise * (1.0 - float(material == 36) * 0.5);
            if (material == 40) {
                emission *= float(albedo.r > 0.6 && albedo.b < 0.3);
            }
			#ifdef OVERWORLD
			emission *= 1.0 - wetness;
			#endif
		}
    } else if (material == 39 && lAlbedo > 0.99) {
        emission = emissionFactor * noise;
        #ifdef OVERWORLD
        emission *= 1.0 - wetness;
        #endif
    }
} else if (material >= 74 && material <= 79) { //Potted flowers
    float emissionFactor = 0.25 * lAlbedo * (0.1 + (1.0 - clamp(length(viewPos) * 0.25, 0.0, 1.0)));
    emission = float(NoU < 0.5 && albedo.g < albedo.r + albedo.b);
    emission *= 1.0 - float(albedo.r > 0.4 && albedo.r < 0.55 && albedo.g < 0.3 && albedo.b > 0.1 && albedo.b < 0.3);
    emission *= emissionFactor;
    #ifdef OVERWORLD
    emission *= 1.0 - wetness;
    #endif
}