void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float density, inout float height) {
    int worldDayInterpolated = int((worldDay * 24000 + worldTime) / 24000);
	float dayAmountFactor = abs(worldDayInterpolated % 7 / 2 - 0.5) * 0.5;
	float dayDensityFactor = abs(worldDayInterpolated % 9 / 4 - worldDayInterpolated % 2);
	float dayFrequencyFactor = 1.0 + abs(worldDayInterpolated % 6 / 4 - worldDayInterpolated % 2) * 0.4;

	amount = mix(amount, 11.5, wetness) - dayAmountFactor;
	density += dayDensityFactor;
	frequency *= dayFrequencyFactor;
}

void getCloudShadow(vec2 rayPos, vec2 wind, float amount, float frequency, float density, inout float noise) {
	rayPos *= 0.0002 * frequency;

	float deformNoise = clamp(texture2D(noisetex, rayPos * 0.1 + wind * 0.25).g * 3.0, 0.0, 1.0);
	float noiseSample = texture2D(noisetex, rayPos * 0.5 + wind * 0.5).r;
	float noiseBase = (1.0 - noiseSample) * 0.35 + 0.25 + wetness * 0.1;

	amount *= 0.7 + deformNoise * 0.3;
	density *= 3.0 - pow3(deformNoise) * 2.0;

	noise = noiseBase * 22.0;
	noise = max(noise - amount, 0.0) * (density * 0.25);
	noise /= sqrt(noise * noise + 0.25);
	noise = exp(-1.5 * noise);
    noise = clamp(noise, 0.0, 1.0);
}