vec3 nvec3(vec4 pos) {
    return pos.xyz / pos.w;
}

float cdist(vec2 coord) {
	return max(abs(coord.x - 0.5), abs(coord.y - 0.5)) * 1.85;
}

const float errMult = 2.2;

vec4 rayTrace(sampler2D depthtex, vec3 viewPos, vec3 normal, float dither, out float border, int refSampleCount, int sampleCount, float refinementMult, float incrementMult) {
	vec3 pos = vec3(0.0);
	float dist = 0.0;

	vec3 start = viewPos + normal * 0.15;

    vec3 rayIncrement = reflect(normalize(viewPos), normalize(normal));
    viewPos += rayIncrement;
	vec3 rayDirection = rayIncrement;

    int refinementPasses = 0;

    for(int i = 0; i < sampleCount; i++) {
        pos = nvec3(gbufferProjection * vec4(viewPos, 1.0)) * 0.5 + 0.5;
		if (pos.x < -0.05 || pos.x > 1.05 || pos.y < -0.05 || pos.y > 1.05) break;

		vec3 rfragpos = vec3(pos.xy, texture2D(depthtex, pos.xy).r);
        rfragpos = nvec3(gbufferProjectionInverse * vec4(rfragpos * 2.0 - 1.0, 1.0));
		dist = abs(dot(normalize(start - rfragpos), normal));

        float err = length(viewPos - rfragpos);
		float lVector = length(rayIncrement) * pow(length(rayDirection), 0.25) * errMult;
		if (err < lVector) {
			refinementPasses++;
			if (refinementPasses >= refSampleCount) break;
			rayDirection -= rayIncrement;
			rayIncrement *= refinementMult;
		}
        rayIncrement *= incrementMult * (0.1 * dither + 0.9);
        rayDirection += rayIncrement;
		viewPos = start + rayDirection;
    }

	border = cdist(pos.st);

	return vec4(pos, dist);
}