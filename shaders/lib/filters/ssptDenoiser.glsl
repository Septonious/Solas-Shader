//huge thanks to niemand for helping me with this filter
float getLinearDepth(float depth) {
   return (near * far) / (depth * (near - far) + far);
}

float gaussian2D(vec2 offset) {
    return 0.159154 * exp(-dot(offset, offset) / 2.0);
}

vec3 denoiseSSPT(sampler2D colortex, vec2 coord) {
    vec3 blur = vec3(0.0);
    vec3 normal = normalize(decodeNormal(texture2D(colortex3, coord).rg));
    vec2 viewResolution = 1.0 / vec2(viewWidth, viewHeight);

	float centerDepth = texture2D(depthtex0, coord.xy).r;
	float linearDepth1 = getLinearDepth(centerDepth);

    float totalWeight = 0.0;

    for (int i = -4; i < 4; i++) {
        for (int j = -4; j < 4; j++) {
            vec2 offset = vec2(i, j) * viewResolution * 4.0 * float(centerDepth > 0.56);

            vec3 currentNormal = normalize(decodeNormal(texture2D(colortex3, coord + offset).xy));
            float currentDepth = getLinearDepth(texture2D(depthtex0, coord + offset).r);
            float depthWeight = clamp(1.0 - abs(linearDepth1 - currentDepth), 0.0001, 1.0);
                  depthWeight = pow8(depthWeight);
            float normalWeight = pow8(clamp(dot(normal, currentNormal), 0.0001, 1.0));
            float weight = depthWeight * normalWeight * gaussian2D(offset);

            blur += texture2D(colortex, coord + offset).rgb * weight;
            totalWeight += weight;
        }
    }
    
    return blur / totalWeight;
}