vec3 nvec3(vec4 pos) {
    return pos.xyz / pos.w;
}

const float errMult = 2.8;

vec3 Raytrace(sampler2D depthtex, vec3 viewPos, vec3 normal, float dither, float fresnel,
			  int refinementSteps, float stepSize, float refMult, float stepLength, int sampleCount, out float border, out float lRfragPos, out float dist, out vec2 cdist) {
	vec3 pos = vec3(0.0);
    vec3 rfragpos = vec3(0.0);
	vec3 start = viewPos + normal * (length(viewPos) * (0.025 - fresnel * 0.025) + 0.05);
    vec3 rayIncrement = stepSize * normalize(reflect(viewPos, normal));
    viewPos += rayIncrement;
	vec3 rayDir = rayIncrement;

    int refinedSamples = 0;

    for (int i = 0; i < sampleCount; i++) {
        pos = nvec3(vxProj * vec4(viewPos, 1.0)) * 0.5 + 0.5;
		if (abs(pos.x - 0.5) > 0.6 || abs(pos.y - 0.5) > 0.55) break;

		rfragpos = vec3(pos.xy, texture2D(depthtex, pos.xy).r);
        rfragpos = nvec3(vxProjInv * vec4(rfragpos * 2.0 - 1.0, 1.0));
		dist = length(start - rfragpos);

        float err = length(viewPos - rfragpos);

        if (err < length(rayIncrement) * errMult) {
			refinedSamples++;
			if (refinedSamples >= refinementSteps) break;
			rayDir -= rayIncrement;
			rayIncrement *= refMult;
		}
        rayIncrement *= stepLength;
        rayDir += rayIncrement * (0.1 * dither + 0.9);
		viewPos = start + rayDir;
    }

    if (pos.z < 0.99997) {
        lRfragPos = length(rfragpos);
        cdist = abs(pos.xy - 0.5) / vec2(0.6, 0.55);
        border = clamp(1.0 - pow2(pow32(max(cdist.x, cdist.y))), 0.0, 1.0);
    }

	return pos;
}