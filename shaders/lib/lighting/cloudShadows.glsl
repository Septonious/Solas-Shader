
void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float thickness, inout float density, inout float height, inout float scale) {
	#ifdef VC_DYNAMIC_WEATHER
	float day = (worldDay * 24000 + worldTime) / 24000;
    float sinDay05 = sin(day * 0.5);
    float cosDay075 = cos(day * 0.75);
    float cosDay15 = cos(day * 1.5);
    float sinDay2 = sin(day * 2.0);
    float waveFunction = sinDay05 * cosDay075 + sinDay2 * 0.25 - cosDay15 * 0.75;

    amount += waveFunction * (0.5 + cosDay075 * 0.5) * 0.5;
    height += waveFunction * sinDay2 * 75.0;
    scale += waveFunction * cosDay075;
    thickness += waveFunction * waveFunction * cosDay15;
    density += waveFunction * sinDay05;
	#endif

    amount = mix(amount, 10.0, wetness);
}

void getCloudShadow(vec2 rayPos, vec2 wind, float amount, float frequency, float density, inout float noise) {
	rayPos *= 0.0035 * frequency;

	float worleyNoise = (1.0 - texture2D(noisetex, rayPos.xy + wind * 0.5).g) * 0.4 + 0.25;
	float perlinNoise = texture2D(noisetex, rayPos.xy + wind * 0.5).r;
	float noiseBase = perlinNoise * 0.6 + worleyNoise * 0.4;

	noise = noiseBase * 21.25;
	noise = max(noise - amount, 0.0) * (density * 0.25);
	noise /= sqrt(noise * noise + 0.25);
    noise = clamp(exp(-noise), 0.0, 1.0);
	noise *= noise * noise;
    noise = mix(1.0, noise, shadowFade);
}