const vec4 cloudParameters[40] = vec4[40](
    vec4(0.000, 0.000, 0.000, 0.000),
    vec4(8.000, 0.080, -0.10, 0.300),
    vec4(22.00, 0.180, -0.30, 0.600),
    vec4(32.00, 0.260, 0.200, 0.950),
    vec4(20.00, 0.150, 0.600, 1.230),
    vec4(10.00, 0.090, 1.000, 1.450),
    vec4(0.000, 0.000, 1.200, 1.780),
    vec4(-10.0, -0.12, 1.700, 2.000),
    vec4(-23.0, -0.20, 2.100, 1.750),
    vec4(-35.0, -0.28, 2.400, 1.520),
    vec4(-17.0, -0.16, 1.900, 1.380),
    vec4(-5.00, -0.04, 1.400, 1.120),
    vec4(5.000, 0.080, 1.000, 0.800),
    vec4(15.00, 0.160, 0.800, 0.550),
    vec4(20.00, 0.240, 0.500, 0.370),
    vec4(10.00, 0.180, 0.200, 0.130),
    vec4(18.00, 0.120, -0.20, -0.15),
    vec4(22.00, 0.000, 0.000, -0.34),
    vec4(11.00, -0.11, -0.50, -0.58),
    vec4(20.00, -0.22, -1.00, -0.42),
    vec4(25.00, -0.34, -1.50, -0.28),
    vec4(35.00, -0.46, -2.00, -0.10),
    vec4(45.00, -0.32, -2.60, 0.100),
    vec4(55.00, -0.18, -3.20, 0.350),
    vec4(70.00, -0.09, -3.60, 0.540),
    vec4(90.00, 0.090, -4.00, 0.830),
    vec4(75.00, 0.170, -3.40, 1.050),
    vec4(60.00, 0.300, -3.00, 1.280),
    vec4(50.00, 0.510, -2.30, 1.100),
    vec4(40.00, 0.400, -1.70, 0.950),
    vec4(30.00, 0.350, -1.20, 0.720),
    vec4(20.00, 0.220, -0.90, 0.580),
    vec4(10.00, 0.100, -0.60, 0.350),
    vec4(0.000, 0.000, -0.20, 0.560),
    vec4(-10.0, -0.10, 0.200, 0.670),
    vec4(-20.0, -0.16, 0.500, 0.520),
    vec4(-35.0, -0.30, 0.800, 0.360),
    vec4(-20.0, -0.13, 0.600, 0.200),
    vec4(-10.0, -0.08, 0.300, 0.100),
    vec4(0.000, 0.000, 0.000, 0.000)
); //height, amount, scale, thickness 

void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float thickness, inout float density, inout float height, inout float scale) {
	//#ifdef VC_DYNAMIC_WEATHER
	//int day = int((worldDay * 24000 + worldTime) / 24000);
	//#endif

	amount = mix(amount, 10.50, wetness);

	#ifdef VC_DYNAMIC_WEATHER
    vec4 weatherParams = cloudParameters[worldDay % 40];
    height += weatherParams.r;
    amount += weatherParams.g;
    scale += weatherParams.b;
    thickness += weatherParams.a;
	#endif
}

void getCloudShadow(vec2 rayPos, vec2 wind, float amount, float frequency, float density, inout float noise) {
	rayPos *= 0.0035 * frequency;

	float worleyNoise = (1.0 - texture2D(noisetex, rayPos.xy + wind * 0.5).g) * 0.4 + 0.25;
	float perlinNoise = texture2D(noisetex, rayPos.xy + wind * 0.5).r;
	float noiseBase = perlinNoise * 0.6 + worleyNoise * 0.4;

	noise = noiseBase * 21.5;
	noise = max(noise - amount, 0.0) * (density * 0.25);
	noise /= sqrt(noise * noise + 0.25);
    noise = clamp(exp(-noise), 0.0, 1.0);
	noise *= noise * noise;
    noise = mix(1.0, noise, min(timeBrightness * timeBrightness + moonVisibility * moonVisibility, 1.0));
}