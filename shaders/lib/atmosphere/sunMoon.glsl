void getSunMoon(inout vec3 color, in vec3 nViewPos, in vec3 lightSun, in vec3 lightNight, in float VoS, in float VoM, in float caveFactor, inout float sunMoon) {
	float visibility = (1.0 - rainStrength) * caveFactor;

	if (visibility > 0.0) {
		float sun = pow32(pow32(VoS * VoS));
		float moon = pow32(pow32(VoM));
		
		if (moon > 0.0 && moonPhase > 0) { // Moon phases, uses the same method as Complementary v4
			float phaseFactor = int(moonPhase != 4) * (1.0 - int(moonPhase > 4) * 2.0) * 0.00175;

			const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
			float ang = fract(timeAngle - (0.25 + phaseFactor));
			ang = (ang + (cos(ang * PI) * -0.5 + 0.5 - ang) / 3.0) * TAU;
			vec3 newSunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

			moon *= clamp(1.0 - pow20(pow32(dot(nViewPos, newSunVec))), 0.0, 1.0);
		}
		
		vec3 sunMoonColor = mix(moon * normalize(lightNight), sun * normalize(lightSun), sunVisibility) * 4.0;
			 sunMoonColor *= clamp(pow8(length(sunMoonColor)), 0.0, 1.0);
			 sunMoonColor = max(sunMoonColor, 0.0) * visibility;
			 
		sunMoon = sun + moon;
		color += sunMoonColor * 3.0;
	}
}