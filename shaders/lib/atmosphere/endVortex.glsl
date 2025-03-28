vec3 getSpiral(vec2 coord, float hole) {
	float whirl = END_VORTEX_WHIRL * mix(1.0, 3.0, pow4(hole));
	float arms = END_VORTEX_ARMS;

    coord = vec2(atan(coord.y, coord.x) - frameTimeCounter * 0.125, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow8(1.0 - coord.y) * 24.0;
    float spiral = sin((coord.x + sqrt(coord.y) * whirl) * arms) + center - coord.y;

    return clamp(endAmbientColSqrt * spiral * 0.125, 0.0, 1.0);
}

void getEndVortex(inout vec3 color, in vec3 worldPos, in vec3 stars, in float VoU, in float VoS) {
	if (0.5 < VoS) {
		vec3 sunVec = mat3(gbufferModelViewInverse) * sunVec;
		vec2 sunCoord = sunVec.xz / (sunVec.y + length(sunVec));
		vec2 planeCoord1 = worldPos.xz / (worldPos.y + length(worldPos)) - sunCoord;

		float ring1 = pow24(pow32(VoS)) * 10000.0;
		float ring2 = pow20(pow32(VoS)) * 10000.0 - ring1 * 5.0;
		float ring3 = pow32(pow32(VoS)) * 2000.0;
		float ring4 = pow24(pow32(VoS)) * 900.0 - ring3 * 5.4;
		float rings = clamp(ring2, 0.0, 1.0) + clamp(pow5(ring4) * 400000, 0.0, 1.0);

		float hole = pow32(pow32(VoS)) * 5000000.0;
			  hole = clamp(hole, 0.0, 1.0);

		vec3 accretionDisk = endLightCol * 12.0;
		vec3 spiral = getSpiral(planeCoord1, VoS);

		color = mix(color, spiral, length(spiral));
		color += endLightCol * pow8(VoS) * 0.075;
		color *= 1.0 - hole;
		color += clamp(rings * accretionDisk, 0.0, 1.0);
	}
}