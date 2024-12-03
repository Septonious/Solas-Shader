vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.x - 0.5), abs(coord.y - 0.5)) * 1.85;
}

const float errMult = 3.0;

vec4 rayTrace(sampler2D depthtex, vec3 viewPos, vec3 normal, float dither, float fresnel, out float border, int refSamples, int samples, float refMult, float incMult) {
	vec3 pos = vec3(0.0);
	float dist = 0.0;

	vec3 start = viewPos + normal * (0.075 + (1.0 - fresnel) * length(viewPos) * 0.125);

    vec3 vector = 0.5 * reflect(normalize(viewPos), normalize(normal));
    viewPos += vector;
	vec3 tvector = vector;

    int refPasses = 0;

    for(int i = 0; i < samples; i++) {
        pos = nvec3(gbufferProjection * nvec4(viewPos)) * 0.5 + 0.5;
		if (pos.x < -0.05 || pos.x > 1.05 || pos.y < -0.05 || pos.y > 1.05) break;

		vec3 rfragpos = vec3(pos.xy, texture2D(depthtex, pos.xy).r);
        rfragpos = nvec3(gbufferProjectionInverse * nvec4(rfragpos * 2.0 - 1.0));
		dist = abs(dot(normalize(start - rfragpos), normal));

		if (length(viewPos - rfragpos) < length(vector) * errMult) {
			refPasses++;
			if (refPasses >= refSamples) break;
			tvector -= vector;
			vector *= refMult;
		}
        vector *= incMult;
        tvector += vector * (0.925 + 0.075 * dither);
		viewPos = start + tvector;
    }

	border = cdist(pos.st);

	return vec4(pos, dist);
}