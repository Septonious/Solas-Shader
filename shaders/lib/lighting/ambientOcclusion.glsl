float GetLinearDepth(float depth, mat4 invProjMatrix) {
    depth = depth * 2.0 - 1.0;
    vec2 zw = depth * invProjMatrix[2].zw + invProjMatrix[3].zw;
    return -zw.x / zw.y;
}

#ifdef DEFERRED_0
vec3 ToView2(vec3 screenPos, mat4 projectionInverse) {
	vec4 viewPos = projectionInverse * (vec4(screenPos, 1.0) * 2.0 - 1.0);
	return viewPos.xyz / viewPos.w;
}

vec3 reconstructNormal(sampler2D depthtex, float linZ, vec3 viewPos, mat4 projectionInverse) {
    float pixelWidth = 1.0 / viewWidth;
    float pixelHeight = 1.0 / viewHeight;

	float eZ = texture2D(depthtex, texCoord.xy + vec2(pixelWidth, 0.0)).r;
	float wZ = texture2D(depthtex, texCoord.xy - vec2(pixelWidth, 0.0)).r;
	float nZ = texture2D(depthtex, texCoord.xy + vec2(0.0, pixelHeight)).r;
	float sZ = texture2D(depthtex, texCoord.xy - vec2(0.0, pixelHeight)).r;

	float eLinZ = GetLinearDepth(eZ, projectionInverse);
	float wLinZ = GetLinearDepth(wZ, projectionInverse);
	float nLinZ = GetLinearDepth(nZ, projectionInverse);
	float sLinZ = GetLinearDepth(sZ, projectionInverse);

	vec3 hDeriv = vec3(0.0);
	bool useE = abs(eLinZ - linZ) < abs(wLinZ - linZ);
	if (useE) {
		vec3 hScreenPos = vec3(texCoord.xy + vec2(pixelWidth, 0.0), eZ);
		vec3 hViewPos = ToView2(hScreenPos, projectionInverse);
		hDeriv = hViewPos - viewPos;
	} else {
		vec3 hScreenPos = vec3(texCoord.xy - vec2(pixelWidth, 0.0), wZ);
		vec3 hViewPos = ToView2(hScreenPos, projectionInverse);
		hDeriv = viewPos - hViewPos;
	}

	vec3 vDeriv = vec3(0.0);
	bool useN = abs(nLinZ - linZ) < abs(sLinZ - linZ);
	if (useN) {
		vec3 vScreenPos = vec3(texCoord.xy + vec2(0.0, pixelHeight), nZ);
		vec3 vViewPos = ToView2(vScreenPos, projectionInverse);
		vDeriv = vViewPos - viewPos;
	} else {
		vec3 vScreenPos = vec3(texCoord.xy - vec2(0.0, pixelHeight), sZ);
		vec3 vViewPos = ToView2(vScreenPos, projectionInverse);
		vDeriv = viewPos - vViewPos;
	}

	vec3 normal = normalize(cross(hDeriv, vDeriv));

	return normal;
}

float calculateAO(float z, sampler2D depthtex, mat4 projectionInverse, float near, float far, float radius, bool isLod) {
	if (z >= 1.0) return 1.0;

	float ao = 0.0;
	float pointiness = 0.0;

	float hand = float(z < 0.56 && !isLod);
	float linZ = GetLinearDepth(z, projectionInverse);

    float dither = Bayer8(gl_FragCoord.xy);
    #ifdef TAA
            dither = fract(frameTimeCounter * 16.0 + dither);
    #endif

	float currentStep = 0.2475 * dither + 0.01;

	float distanceScale = max(linZ, 2.5);
	float fovScale = gbufferProjection[1][1] / 1.37;
	vec2 scale = radius * vec2(1.0 / aspectRatio, 1.0) * fovScale / distanceScale;
	float differenceScale = linZ / distanceScale;

    dither *= 6.28;
	vec2 baseOffset = vec2(cos(dither), sin(dither));

	vec3 viewPos = ToView2(vec3(texCoord.xy, z), projectionInverse);
	vec3 normal = reconstructNormal(depthtex, linZ, viewPos, projectionInverse);
	float angleThreshold = isLod ? 0.15 : (0.15 + linZ * 0.01);

	for (int i = 0; i < 4; i++) {
		vec2 offset = baseOffset * currentStep * scale;
		float visibility = 0.0;

		for(int j = 0; j < 2; j++){
			vec2 sampleCoord = texCoord + offset;
			float sampleZ = texture2D(depthtex, sampleCoord).r;
			vec3 sampleViewPos = ToView2(vec3(sampleCoord, sampleZ), projectionInverse);
			vec3 difference = (sampleViewPos.xyz - viewPos.xyz) / (radius * currentStep * differenceScale);
			float attenuation = clamp(1.0 + 0.5 / currentStep - 0.25 * length(difference), 0.0, 1.0);
			
			if (hand > 0.5) {
				visibility += clamp(0.5 - difference.z * 4096.0, 0.0, 1.0);
			}else {
				float angle = dot(normal, normalize(difference)) * (1.0 + angleThreshold);
				visibility += 0.5 - max(angle - angleThreshold, 0.0) * attenuation;
				pointiness += max(-angle - angleThreshold, 0.0);
			}

			offset = -offset;
		}
		
		ao += clamp(visibility, 0.0, 1.0);

		currentStep += 0.2475;
		baseOffset = vec2(baseOffset.x - baseOffset.y, baseOffset.x + baseOffset.y) * 0.7071;
	}
	ao *= 0.25;
	pointiness *= 0.25;

	return mix(ao, 1.0, pointiness);
}
#else
const vec2 aoSampleOffsets[4] = vec2[4](
	vec2( 1.5,  0.5),
	vec2(-0.5,  1.5),
	vec2(-1.5, -0.5),
	vec2( 0.5, -1.5)
);

const vec2 aoDepthOffsets[4] = vec2[4](
	vec2( 2.0,  1.0),
	vec2(-1.0,  2.0),
	vec2(-2.0, -1.0),
	vec2( 1.0, -2.0)
);

float getAmbientOcclusion(float z, sampler2D depthtex, mat4 projectionInverse){
	float ao = 0.0;
	float tw = 0.0;
	float lz = GetLinearDepth(z, projectionInverse);
	
	for(int i = 0; i < 4; i++){
		vec2 sampleOffset = aoSampleOffsets[i] / vec2(viewWidth, viewHeight);
		vec2 depthOffset = aoDepthOffsets[i] / vec2(viewWidth, viewHeight);
		float samplez = GetLinearDepth(texture2D(depthtex, texCoord + depthOffset).r, projectionInverse);
		float wg = max(1.0 - 4.0 * abs(lz - samplez), 0.00001);
		ao += texture2D(colortex5, texCoord + sampleOffset).g * wg;
		tw += wg;
	}
	ao /= tw;
	if (tw < 0.0001) ao = texture2D(colortex5, texCoord).g;
	
	return pow(ao, AO_STRENGTH);
}
#endif