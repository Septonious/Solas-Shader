void getRainbow(inout vec3 color, in vec3 worldPos, in float VoU, in float size, in float radius, in float caveFactor) {
	float visibility = pow3(sunVisibility) * (1.0 - rainStrength) * (1.0 - isSnowy) * wetness * max(VoU, 0.0) * caveFactor * RAINBOW_BRIGHTNESS;

	if (0 < visibility) {
		vec2 planeCoord = worldPos.xy / (worldPos.y + length(worldPos.xz) * 0.65);
		vec2 rainbowCoord = vec2(planeCoord.x + mix(2.5, -2.5, timeAngle), planeCoord.y );

		float rainbowFactor = clamp(1.0 - length(rainbowCoord) / size, 0.0, 1.0);
		
		vec3 rainbow = 
			(smoothstep(0.0, radius, rainbowFactor) - smoothstep(radius, radius * 2.0, rainbowFactor)) * vec3(0.25, 0.0, 0.0) +
			(smoothstep(radius * 0.5, radius * 1.5, rainbowFactor) - smoothstep(radius * 1.5, radius * 2.5, rainbowFactor)) * vec3(0.0, 0.25, 0.0) +
			(smoothstep(radius, radius * 2.0, rainbowFactor) - smoothstep(radius * 2.0, radius * 3.0, rainbowFactor)) * vec3(0.0, 0.0, 0.25)
		;

		color += rainbow * visibility;
	}
}