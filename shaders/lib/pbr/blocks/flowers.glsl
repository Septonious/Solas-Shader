else if (material >= 35 && material < 40) {
	float emissionFactor = lAlbedo * (0.1 + (1.0 - clamp(length(viewPos) * 0.4, 0.0, 1.0)));
	float noise = texture2D(noisetex, (worldPos.xz + cameraPosition.xz + frameCounter * 0.01) * 0.001).b;
		  noise = 0.75 + clamp(noise - 0.4, 0.0, 1.0);
	if (albedo.r + albedo.g + albedo.b < 2.9) {
		if (albedo.b > albedo.g || albedo.r > albedo.g) {
			emission = emissionFactor * noise;
			if (material == 36) emission *= 0.5;
			#ifdef OVERWORLD
			emission *= mix(1.0, 0.0, wetness);
			#endif
		}
	}
	if (material == 39 && lAlbedo > 0.99) {
		emission = emissionFactor * lAlbedo;
		#ifdef OVERWORLD
		emission *= mix(1.0, 0.0, wetness);
		#endif
	}
} else if (material == 40) {
	float emissionFactor = lAlbedo * (0.1 + (1.0 - clamp(length(viewPos) * 0.4, 0.0, 1.0)));
	float noise = texture2D(noisetex, (worldPos.xz + cameraPosition.xz + frameCounter * 0.01) * 0.001).b;
		  noise = 0.75 + clamp(noise - 0.4, 0.0, 1.0);
	if (albedo.r + albedo.g + albedo.b < 2.9) {
		if (albedo.b > albedo.g || albedo.r > albedo.g) {
			emission = emissionFactor * noise * float(albedo.r > 0.6 && albedo.b < 0.3);
			#ifdef OVERWORLD
			emission *= mix(1.0, 0.0, wetness);
			#endif
		}
	}
} else if (material >= 74 && material <= 79) {
	float emissionFactor = lAlbedo * (0.1 + (1.0 - clamp(length(viewPos) * 0.4, 0.0, 1.0)));
	float noise = texture2D(noisetex, (worldPos.xz + cameraPosition.xz + frameCounter * 0.01) * 0.001).b;
		  noise = 0.75 + clamp(noise - 0.4, 0.0, 1.0);
	if (albedo.r + albedo.g + albedo.b < 2.9) {
		if (albedo.b > albedo.g || albedo.r > albedo.g) {
			emission = emissionFactor * noise * (float(lAlbedo > 0.63) * (float(albedo.r + albedo.g * 0.5 + albedo.b * 0.5 > 0.9) + float(albedo.r - albedo.g - albedo.b > 0.3)));
			#ifdef OVERWORLD
			emission *= mix(1.0, 0.0, wetness);
			#endif
		}
	}
}