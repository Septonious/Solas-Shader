void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float density, inout float height) {
    int worldDayInterpolated = int((worldDay * 24000 + worldTime) / 24000);
	float dayAmountFactor = abs(worldDayInterpolated % 7 / 2 - 0.5) * 0.5;
	float dayDensityFactor = abs(worldDayInterpolated % 9 / 4 - worldDayInterpolated % 2);
	float dayFrequencyFactor = 1.0 + abs(worldDayInterpolated % 6 / 4 - worldDayInterpolated % 2) * 0.65;

	amount = mix(amount, 11.5, wetness) - dayAmountFactor;
	density += dayDensityFactor;
	frequency *= dayFrequencyFactor;
}


void getCloudShadow(vec2 rayPos, vec2 wind, float amount, float frequency, float density, inout float noise) {
	rayPos *= 0.0002 * frequency;

	float noiseBase = texture2D(noisetex, rayPos + 0.5 + wind * 0.5).g;
		  noiseBase = (1.0 - noiseBase) * 0.35 + 0.25 + wetness * 0.1;

	noise = noiseBase * 22.0;
	noise = max(noise - amount, 0.0) * (density * 0.25);
	noise /= sqrt(noise * noise + 0.25);
	noise = exp(noise * -2.0);
    noise = clamp(noise, 0.0, 1.0);
}