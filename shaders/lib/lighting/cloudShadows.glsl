void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float thickness, inout float density, inout float height, inout float scale) {
	#ifdef VC_DYNAMIC_WEATHER
	int day = int((worldDay * 24000 + worldTime) / 24000);
	float dayAmountFactor = abs(day % 7 / 2 - 0.5) * 0.5;
	float dayDensityFactor = abs(day % 9 / 4 - day % 2);
	float dayFrequencyFactor = 1.0 + abs(day % 6 / 4 - day % 2) * 0.4;
    float dayScaleFactor = (day % 5 - day % 8 + day % 3) * 0.5;
	float dayHeightFactor = day % 5 + day % 18 + day % 27 - day % 33 - 10;
	#endif

	amount = mix(amount, 10.50, wetness);

	#ifdef VC_DYNAMIC_WEATHER
	amount -= dayAmountFactor;
	thickness += dayFrequencyFactor - 0.75;
	density += dayDensityFactor;
    scale += dayScaleFactor;
	height += dayHeightFactor;
	#endif
}

void getCloudShadow(vec2 rayPos, vec2 wind, float amount, float frequency, float density, inout float noise) {
	rayPos *= 0.0035 * frequency;

	float worleyNoise = (1.0 - texture2D(noisetex, rayPos.xy + wind * 0.5).g) * 0.4 + 0.25;
	float perlinNoise = texture2D(noisetex, rayPos.xy + wind * 0.5).r;
	float noiseBase = perlinNoise * 0.6 + worleyNoise * 0.4;

	noise = noiseBase * 22.0;
	noise = max(noise - amount, 0.0) * (density * 0.25);
	noise /= sqrt(noise * noise + 0.25);
	noise = exp(-1.5 * noise);
    noise = clamp(noise, 0.0, 1.0);
}