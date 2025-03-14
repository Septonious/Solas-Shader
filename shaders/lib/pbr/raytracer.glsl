vec3 nvec3(vec4 pos) {
    return pos.xyz / pos.w;
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

    vec3 rayDir = 0.5 * reflect(normalize(viewPos), normalize(normal));
	vec3 viewPosRT = viewPos + rayDir;
	vec3 rayPos = rayDir;
	vec3 rfragpos = vec3(0.0);

    for(int i = 0; i < samples; i++) {
        pos = nvec3(gbufferProjection * nvec4(viewPosRT)) * 0.5 + 0.5;
		if (abs(pos.x - 0.5) > 0.6 || abs(pos.y - 0.5) > 0.55) break;

		rfragpos = vec3(pos.xy, texture2D(depthtex, pos.xy).r);
        rfragpos = nvec3(gbufferProjectionInverse * nvec4(rfragpos * 2.0 - 1.0));
		dist = length(start - rfragpos);

		for (int j = 0; j < refSamples; j++) {
			if (length(viewPosRT - rfragpos) < length(rayDir) * errMult) {
				rayPos -= rayDir;
				rayDir *= refMult;
			}
		}

        rayDir *= incMult;
        rayPos += rayDir * (0.95 + 0.05 * dither);
		viewPosRT = start + rayPos;
    }

	border = cdist(pos.st);

	return vec4(pos, dist);
}