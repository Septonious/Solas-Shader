void getSunMoon(inout vec3 color, in vec3 nViewPos, in vec3 lightSun, in vec3 lightNight, in float VoS, in float VoM, in float caveFactor, inout float sunMoon) {
	float visibility = (1.0 - rainStrength) * caveFactor;

	if (visibility > 0.0) {
		float VoSM = mix(VoM, VoS, sunVisibility);
		float glareDisk = clamp(VoSM * 0.5 + 0.5, 0.0, 1.0);
			  glareDisk = 0.01 / (1.0 - 0.99 * glareDisk) - 0.01;

		float sun = pow32(pow32(VoS * VoS));
		float moon = pow32(pow32(VoM));

		if (moon > 0.0 && moonPhase > 0) { // Moon phases, uses the same method as Complementary v4
			float phaseFactor = float(moonPhase != 4) * (1.0 - float(moonPhase > 4) * 2.0) * 0.00175;

			const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
			float ang = fract(timeAngle - (0.25 + phaseFactor));
			ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
			vec3 newSunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

			moon *= clamp(1.0 - pow24(pow32(dot(nViewPos, newSunVec))), 0.0, 1.0);
		}
		
		vec3 sunMoonColor = sun * lightSun * sunVisibility + moon * lightNight * 8.0 * (1.0 - sunVisibility);
			 sunMoonColor*= pow8(length(sunMoonColor));
			 sunMoonColor+= glareDisk * lightColSqrt * 0.5 * (1.0 - moonPhase * 0.2);
			 sunMoonColor = clamp(sunMoonColor, 0.0, 1.0) * visibility;
			 
		sunMoon = sun + moon;
		color += mix(vec3(0.0), vec3(15.0 * sunMoonColor), sunMoon) + sunMoonColor;
	}
}