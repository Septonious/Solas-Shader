void getChromaticAberration(inout vec3 color, in vec2 coord) {
	float strength = 0.01 * CHROMATIC_ABERRATION_STRENGTH;
	vec2 viewScale = vec2(1.0 / aspectRatio, 1.0);
	color *= vec3(0.0, 1.0, 0.0);
	color += texture2D(colortex0, mix(coord, vec2(0.5), viewScale * -strength)).rgb * vec3(1.0, 0.0, 0.0);
	color += texture2D(colortex0, mix(coord, vec2(0.5), viewScale * -strength * 0.5)).rgb * vec3(0.5, 0.5, 0.0);
	color += texture2D(colortex0, mix(coord, vec2(0.5), viewScale * strength * 0.5)).rgb * vec3(0.0, 0.5, 0.5);
	color += texture2D(colortex0, mix(coord, vec2(0.5), viewScale * strength)).rgb * vec3(0.0, 0.0, 1.0);

	color /= vec3(1.5, 2.0, 1.5);
}