
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

	#if MC_VERSION >= 12104
    amount -= isPaleGarden;
	#endif
}

float cloudSampleBasePerlinWorley(vec2 coord) {
	float noiseBase = texture2D(noisetex, coord).g;
	      noiseBase = pow(1.0 - noiseBase, 1.5) * 0.45 + 0.15;
		  noiseBase += texture2D(noisetex, coord * 2.0).r * 0.25;

	return noiseBase;
}

float CloudCoverageDefault(float sampleAltitude, float amount) {
	float noiseCoverage = abs(sampleAltitude - 0.125);

	noiseCoverage *= sampleAltitude > 0.125 ? (2.14 - amount * 0.1) : 8.0;
	noiseCoverage = noiseCoverage * noiseCoverage * 4.0;

	return noiseCoverage;
}

float CloudApplyDensity(float noise, float density) {
	noise *= density * 0.125;
	noise *= (1.0 - 0.25 * wetness);
	noise = noise / sqrt(noise * noise + 0.5);

	return noise;
}

float CloudCombineDefault(float noiseBase, float noiseDetail, float noiseCoverage, float amount, float density) {
	float noise = noiseBase * 21.0;

	noise = fmix(noise - noiseCoverage, 21.0 - noiseCoverage * 2.5, 0.25 * wetness);
	noise = max(noise - amount - 0.05, 0.0);

	noise = CloudApplyDensity(noise, density);

	return noise;
}

void getCloudShadow(vec2 coord, vec2 wind, float amount, float frequency, float density, inout float noise) {
	coord *= 0.004 * frequency;

	vec2 baseCoord = coord * 0.5 + wind * 2.0;
	float noiseBase = cloudSampleBasePerlinWorley(baseCoord);

	noise = CloudCombineDefault(noiseBase, 0.0, 0.5, amount, density);
	noise = clamp(exp(-3.5 * noise), 0.0, 1.0);
    noise = fmix(1.0, noise, shadowFade);
}