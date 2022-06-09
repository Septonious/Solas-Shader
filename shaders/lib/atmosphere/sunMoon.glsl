void getSunMoon(inout vec3 color, in float VoS, in float VoM, in float VoU, in vec3 lightSun, in vec3 lightNight) {
	float visibility = 16.0 * (1.0 - rainStrength);

	vec3 sun = pow20(pow24(VoS)) * pow4(lightSun) * visibility;
	vec3 moon = pow24(pow24(VoM)) * lightNight * visibility;

	color += (sun + moon) * pow2(max(VoU, 0.0));
}