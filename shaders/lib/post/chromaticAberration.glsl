void getWaterChromaticAberration(sampler2D colortex, inout vec3 color, in vec2 coord, in vec2 distort) {
	distort *= 2.0;
	vec2 viewScale = vec2(1.0 / aspectRatio, 1.0);

	color *= vec3(0.0, 1.0, 0.0);
	color += texture2D(colortex, mix(coord, vec2(0.5), distort.x)).rgb * vec3(1.0, 0.0, 0.0);
	color += texture2D(colortex, mix(coord, vec2(0.5), distort.x * 0.5)).rgb * vec3(0.5, 0.5, 0.0);
	color += texture2D(colortex, mix(coord, vec2(0.5), distort.y * 0.5)).rgb * vec3(0.0, 0.5, 0.5);
	color += texture2D(colortex, mix(coord, vec2(0.5), distort.y)).rgb * vec3(0.0, 0.0, 1.0);

	color /= vec3(1.5, 2.0, 1.5);
}

void getChromaticAberration(sampler2D colortex, inout vec3 color, in vec2 coord) {
	const float strength = 0.01 * CHROMATIC_ABERRATION_STRENGTH;
	vec2 viewScale = vec2(1.0 / aspectRatio, 1.0);

	color *= vec3(0.0, 1.0, 0.0);
	color += texture2D(colortex, mix(coord, vec2(0.5), viewScale * -strength)).rgb * vec3(1.0, 0.0, 0.0);
	color += texture2D(colortex, mix(coord, vec2(0.5), viewScale * -strength * 0.5)).rgb * vec3(0.5, 0.5, 0.0);
	color += texture2D(colortex, mix(coord, vec2(0.5), viewScale *  strength * 0.5)).rgb * vec3(0.0, 0.5, 0.5);
	color += texture2D(colortex, mix(coord, vec2(0.5), viewScale *  strength)).rgb * vec3(0.0, 0.0, 1.0);

	color /= vec3(1.5, 2.0, 1.5);
}