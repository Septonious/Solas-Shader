void getSunMoon(inout vec3 color, in float VoS, in float VoM, in float VoU, in vec3 lightSun, in vec3 lightNight) {
	float visibility = 512.0 * (1.0 - rainStrength);

	vec3 sun = pow32(pow32(VoS)) * pow4(lightSun) * visibility;
	vec3 moon = pow4(pow32(pow32(VoM))) * lightNight * visibility;

	color += (sun + moon) * pow4(max(VoU, 0.0));
}