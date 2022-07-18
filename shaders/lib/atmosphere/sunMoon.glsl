void getSunMoon(inout vec3 color, in vec3 nViewPos, in vec3 lightSun, in vec3 lightNight, in float VoS, in float VoM, in float VoU, in float ug) {
	float visibility = (1.0 - rainStrength) * ug;

	if (visibility > 0.0) {
		float sun = pow16(pow32(VoS));
		float moon = pow32(pow32(VoM));
		float sunGlare = pow24(VoS);
		float moonGlare = pow24(VoM);

		if (moon > 0.0 && moonPhase > 0) { // Moon phases, uses the same method as Complementary v4
			float phaseFactor = float(moonPhase != 4) * (1.0 - float(moonPhase > 4) * 2.0) * 0.00125;

			const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
			float ang = fract(timeAngle - (0.25 + phaseFactor));
			ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
			vec3 newSunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

			moon *= clamp(1.0 - pow32(pow32(dot(nViewPos, newSunVec))), 0.0, 1.0);
		}
		
		vec3 sunAndMoon = sun * lightSun * sunVisibility + moon * lightNight * 9.0 * (1.0 - sunVisibility);
			 sunAndMoon*= pow16(length(sunAndMoon));
			 sunAndMoon+= sunGlare * lightSun * 0.3 * sunVisibility + moonGlare * lightNight * 0.5 * (1.0 - sunVisibility);

		color += sunAndMoon * visibility;
	}
}