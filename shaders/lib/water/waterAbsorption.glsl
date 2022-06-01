const vec3 scatteringCoeff = vec3(0.025, 0.25, 1.0);
const vec3 transmittanceCoeff = vec3(1.0, 0.25, 0.025);

vec3 getWaterAbsorption(vec3 color, vec3 waterColor, vec3 viewPos, vec3 viewPosZ1, float skylight) {
	float visfactor = pow4((1.0 - rainStrength * 0.95) * skylight);
	vec3 absorbColor = waterColor * visfactor;

	float density = abs(length(viewPosZ1 - viewPos)) * visfactor;
    	  density = clamp(density * ABSORPTION_DENSITY, 0.0, 2.0);

    vec3 scattering = 1.0 - exp(-density * scatteringCoeff);
    vec3 transmittance = exp(-density * 0.75 * transmittanceCoeff);

    return color * transmittance + absorbColor * scattering * 0.05;
}