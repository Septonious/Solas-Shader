vec3 getSpiral(vec2 coord, float hole) {
	float whirl = END_VORTEX_WHIRL * mix(1.0, 3.0, pow4(hole));
	float arms = END_VORTEX_ARMS;

    coord = vec2(atan(coord.y, coord.x) - frameTimeCounter * 0.125, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow8(1.0 - coord.y) * 24.0;
    float spiral = sin((coord.x + sqrt(coord.y) * whirl) * arms) + center - coord.y;

    return clamp(endAmbientColSqrt * spiral * 0.15, 0.0, 1.0);
}

void getEndVortex(inout vec3 color, in vec3 worldPos, in vec3 stars, in float VoU, in float VoS) {
	if (0.5 < VoS) {
		vec3 sunVec = mat3(gbufferModelViewInverse) * sunVec;
		vec2 sunCoord = sunVec.xz / (sunVec.y + length(sunVec));
		vec2 planeCoord0 = worldPos.xz / (worldPos.y + length(worldPos)) + sunCoord;
			 planeCoord0.x += 0.5;
			 planeCoord0.y -= 0.23;
		vec2 planeCoord1 = worldPos.xz / (worldPos.y + length(worldPos)) - sunCoord;
		vec2 center = vec2(0.5);
		
		float dist = distance(planeCoord0, center);
		float invDist = 1.0 - dist;
		float ring = pow(smoothstep(0.3, 0.05, dist * 1.5) * 4.0, 3.5) + 1.0;

		float hole = step(0.05, dist);
			  hole *= smoothstep(0.085, 0.100, dist);

		vec3 accretionDisk = endLightCol * pow7(invDist) * 0.25;
		vec3 spiral = getSpiral(planeCoord1, VoS);

		color = mix(color, spiral, length(spiral));
		color += clamp(ring * hole * accretionDisk, 0.0, 1.0);
		color *= mix(1.0, 0.0, float(0.97 < VoS) * (1.0 - hole));
	}
}