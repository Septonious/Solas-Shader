const vec4 cloudParameters[80] = vec4[80](
    vec4(0.000, 0.000, 0.000, 0.000),
    vec4(8.000, 0.080, -0.10, 0.500),
    vec4(22.00, 0.180, -0.30, 1.050),
    vec4(32.00, 0.260, 0.200, 1.650),
    vec4(20.00, 0.150, 0.600, 2.330),
    vec4(10.00, 0.090, 1.000, 2.950),
    vec4(0.000, 0.000, 1.200, 3.480),
    vec4(-10.0, -0.12, 1.700, 3.800),
    vec4(-23.0, -0.20, 2.100, 3.250),
    vec4(-35.0, -0.28, 2.400, 2.820),
    vec4(-17.0, -0.16, 1.900, 2.380),
    vec4(-5.00, -0.04, 1.400, 1.820),
    vec4(5.000, 0.080, 1.000, 2.200),
    vec4(15.00, 0.160, 0.800, 1.550),
    vec4(20.00, 0.240, 0.500, 1.070),
    vec4(10.00, 0.180, 0.200, 0.630),
    vec4(18.00, 0.120, -0.20, 0.200),
    vec4(22.00, 0.000, 0.000, -0.14),
    vec4(11.00, -0.11, -0.50, -0.48),
    vec4(20.00, -0.22, -1.00, -0.76),
    vec4(25.00, -0.34, -1.50, -0.58),
    vec4(35.00, -0.46, -2.00, -0.30),
    vec4(45.00, -0.32, -2.60, 0.100),
    vec4(55.00, -0.18, -3.20, 0.350),
    vec4(70.00, -0.09, -3.60, 0.540),
    vec4(90.00, 0.090, -4.00, 0.830),
    vec4(75.00, 0.170, -3.40, 1.250),
    vec4(60.00, 0.300, -3.00, 1.680),
    vec4(50.00, 0.510, -2.30, 1.300),
    vec4(40.00, 0.400, -1.70, 0.950),
    vec4(30.00, 0.350, -1.20, 0.620),
    vec4(20.00, 0.220, -0.90, 0.380),
    vec4(10.00, 0.100, -0.60, 0.050),
    vec4(0.000, 0.000, -0.20, -0.15),
    vec4(-10.0, -0.10, 0.200, -0.40),
    vec4(-20.0, -0.16, 0.500, -0.20),
    vec4(-35.0, -0.30, 0.800, 0.050),
    vec4(-20.0, -0.13, 0.600, 0.400),
    vec4(-10.0, -0.08, 0.300, 0.200),
    vec4(0.000, 0.000, 0.000, 0.000),
    vec4(-10.0, -0.10, -0.10, 0.000),
    vec4(-20.0, -0.18, -0.20, 0.500),
    vec4(-25.0, -0.24, -0.25, 1.050),
    vec4(-30.0, -0.32, -0.40, 1.650),
    vec4(-40.0, -0.42, -0.60, 2.330),
    vec4(-45.0, -0.50, -0.90, 2.950),
    vec4(-55.0, -0.40, -1.20, 3.480),
    vec4(-65.0, -0.32, -1.70, 3.800),
    vec4(-70.0, -0.20, -1.50, 3.250),
    vec4(-90.0, -0.12, -1.20, 2.820),
    vec4(-100., -0.04, -1.00, 2.380),
    vec4(-90.0, 0.000, -0.70, 1.820),
    vec4(-80.0, 0.080, -0.57, 2.200),
    vec4(-70.0, 0.160, -0.38, 1.550),
    vec4(-60.0, 0.240, -0.19, 1.070),
    vec4(-50.0, 0.330, 0.000, 0.630),
    vec4(-40.0, 0.420, -0.10, 0.200),
    vec4(-50.0, 0.500, -0.25, -0.14),
    vec4(-60.0, 0.400, -0.35, -0.48),
    vec4(-70.0, 0.320, -0.50, -0.76),
    vec4(-65.0, 0.260, -0.70, -0.58),
    vec4(-55.0, 0.200, -0.90, -0.30),
    vec4(-45.0, 0.140, -1.05, 0.100),
    vec4(-40.0, 0.080, -1.20, 0.350),
    vec4(-30.0, 0.000, -1.35, 0.540),
    vec4(-20.0, 0.090, -1.50, 0.830),
    vec4(-10.0, 0.170, -1.70, 1.250),
    vec4(0.000, 0.250, -1.85, 1.680),
    vec4(10.00, 0.340, -2.00, 1.300),
    vec4(20.00, 0.420, -1.85, 0.950),
    vec4(30.00, 0.360, -1.70, 0.620),
    vec4(20.00, 0.250, -1.55, 0.380),
    vec4(10.00, 0.130, -1.30, 0.000),
    vec4(0.000, 0.060, -1.05, -0.15),
    vec4(-10.0, -0.05, -0.85, -0.40),
    vec4(-20.0, -0.12, -0.70, -0.20),
    vec4(-35.0, -0.23, -0.50, 0.050),
    vec4(-20.0, -0.09, -0.30, 0.300),
    vec4(-10.0, -0.03, -0.10, 0.200),
    vec4(0.000, 0.000, 0.000, 0.000)
); //height, amount, scale, thickness 

void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float thickness, inout float density, inout float height, inout float scale) {
	//#ifdef VC_DYNAMIC_WEATHER
	//int day = int((worldDay * 24000 + worldTime) / 24000);
	//#endif

	#ifdef VC_DYNAMIC_WEATHER
    vec4 weatherParams = cloudParameters[worldDay % 80];
    height += weatherParams.r;
    amount += weatherParams.g;
    scale += weatherParams.b;
    thickness += weatherParams.a;
	#endif

    amount = mix(amount, 10.0, wetness);
}

void getCloudShadow(vec2 rayPos, vec2 wind, float amount, float frequency, float density, inout float noise) {
	rayPos *= 0.0035 * frequency;

	float worleyNoise = (1.0 - texture2D(noisetex, rayPos.xy + wind * 0.5).g) * 0.4 + 0.25;
	float perlinNoise = texture2D(noisetex, rayPos.xy + wind * 0.5).r;
	float noiseBase = perlinNoise * 0.6 + worleyNoise * 0.4;

	noise = noiseBase * 21;
	noise = max(noise - amount, 0.0) * (density * 0.25);
	noise /= sqrt(noise * noise + 0.25);
    noise = clamp(exp(-noise), 0.0, 1.0);
	noise *= noise * noise;
    noise = mix(1.0, noise, min(timeBrightness * timeBrightness + moonVisibility * moonVisibility, 1.0));
}