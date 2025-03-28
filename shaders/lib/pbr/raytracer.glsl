vec3 nvec3(vec4 pos) {
    return pos.xyz / pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.x - 0.5), abs(coord.y - 0.5)) * 1.85;
}

const float errMult = 2.2;

vec4 rayTrace(sampler2D depthtex, vec3 viewPos, vec3 normal, float dither, float fresnel, out float border, int refSamples, int samples, float refMult, float incMult) {
	vec3 pos = vec3(0.0);
	float dist = 0.0;

	vec3 start = viewPos + normal * (0.075 + (1.0 - fresnel) * length(viewPos) * 0.125);

    vec3 rayDir = 0.5 * reflect(normalize(viewPos), normalize(normal));
	vec3 viewPosRT = viewPos + rayDir;
	vec3 rayPos = rayDir;
	vec3 rfragpos = vec3(0.0);
	int refinementPasses = 0;

    for(int i = 0; i < samples; i++) {
        pos = nvec3(gbufferProjection * vec4(viewPosRT, 1.0)) * 0.5 + 0.5;
		if (pos.x < -0.05 || pos.x > 1.05 || pos.y < -0.05 || pos.y > 1.05) break;

		vec3 rfragpos = vec3(pos.xy, texture2D(depthtex,pos.xy).r);
        rfragpos = nvec3(gbufferProjectionInverse * vec4(rfragpos * 2.0 - 1.0, 1.0));
		dist = abs(dot(normalize(start - rfragpos), normal));

        float err = length(viewPosRT - rfragpos);
		float lVector = length(rayDir) * pow(length(rayPos), 0.1) * errMult;
		if (err < lVector) {
			refinementPasses++;
			if (refinementPasses >= refSamples) break;
			rayPos -= rayDir;
			rayDir *= refMult;
		}
        rayDir *= incMult;
        rayPos += rayDir * (0.15 * dither + 0.85);
		viewPosRT = start + rayPos;
    }

	border = cdist(pos.st);

	return vec4(pos, dist);
}