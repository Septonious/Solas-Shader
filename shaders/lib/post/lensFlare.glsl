//Lens flare from BSL
float fovmult = gbufferProjection[1][1] / 1.37373871;

float GetLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

vec2 GetLightPos() {
	vec4 tpos = gbufferProjection * vec4(sunPosition, 1.0);
	tpos.xyz /= tpos.w;
	return tpos.xy / tpos.z * 0.5;
}

float BaseLens(vec2 lightPos, float size, float dist, float hardness) {
	vec2 lensCoord = (texCoord + (lightPos * dist - 0.5)) * vec2(aspectRatio, 1.0);
	float lens = clamp(1.0 - length(lensCoord) / (size * fovmult), 0.0, 1.0 / hardness) * hardness;
	lens *= lens; lens *= lens;
	return lens;
}

float OverlapLens(vec2 lightPos, float size, float dista, float distb) {
	return BaseLens(lightPos, size, dista, 2.0) * BaseLens(lightPos, size, distb, 2.0);
}

float PointLens(vec2 lightPos, float size, float dist) {
	return BaseLens(lightPos, size, dist, 1.5) + BaseLens(lightPos, size * 4.0, dist, 1.0) * 0.5;
}

float RingLensTransform(float lensFlare) {
	return pow(1.0 - pow(1.0 - pow(lensFlare, 0.25), 10.0), 5.0);
}
float RingLens(vec2 lightPos, float size, float distA, float distB) {
	float lensFlare1 = RingLensTransform(BaseLens(lightPos, size, distA, 1.0));
	float lensFlare2 = RingLensTransform(BaseLens(lightPos, size, distB, 1.0));
	
	float lensFlare = clamp(lensFlare2 - lensFlare1, 0.0, 1.0);
	lensFlare *= sqrt(lensFlare);
	return lensFlare;
}

float AnamorphicLens(vec2 lightPos, float size, float dist) {
	vec2 lensCoord = abs(texCoord + (lightPos.xy * dist - 0.5)) * vec2(aspectRatio * 0.07, 2.0);
	float lens = clamp(1.0 - length(pow(lensCoord / (size * fovmult), vec2(0.85))) * 4.0, 0.0, 1.0);
	lens *= lens * lens;
	return lens;
}

vec3 RainbowLens(vec2 lightPos, float size, float dist, float rad) {
	vec2 lensCoord = (texCoord + (lightPos * dist - 0.5)) * vec2(aspectRatio,1.0);
	float lens = clamp(1.0 - length(lensCoord) / (size * fovmult), 0.0, 1.0);
	
	vec3 rainbowLens = 
		(smoothstep(0.0, rad, lens) - smoothstep(rad, rad * 2.0, lens)) * vec3(1.0, 0.0, 0.0) +
		(smoothstep(rad * 0.5, rad * 1.5, lens) - smoothstep(rad * 1.5, rad * 2.5, lens)) * vec3(0.0, 1.0, 0.0) +
		(smoothstep(rad, rad * 2.0, lens) - smoothstep(rad * 2.0, rad * 3.0, lens)) * vec3(0.0, 0.0, 1.0)
	;

	return rainbowLens;
}

vec3 LensTint(vec3 lens, float truePos) {
	float isMoon = truePos * 0.5 + 0.5;

	float visibility = mix(sunVisibility,moonVisibility, isMoon);
	lens = mix(lens, GetLuminance(lens) * lightNight, isMoon * 0.98);
	return lens * visibility;
}

void LensFlare(inout vec3 color, vec2 lightPos, float truePos, float multiplier) {
	float falloffBase = length(lightPos * vec2(aspectRatio, 1.0));
	float falloffIn = pow(clamp(falloffBase * 10.0, 0.0, 1.0), 2.0);
	float falloffOut = clamp(falloffBase * 3.0 - 1.5, 0.0, 1.0);

	if (falloffOut < 0.999) {
		vec3 lensFlare = (
			BaseLens(lightPos, 0.3, -0.45, 1.0) * vec3(2.2, 1.2, 0.1) * 0.07 +
			BaseLens(lightPos, 0.3,  0.10, 1.0) * vec3(2.2, 0.4, 0.1) * 0.03 +
			BaseLens(lightPos, 0.3,  0.30, 1.0) * vec3(2.2, 0.2, 0.1) * 0.04 +
			BaseLens(lightPos, 0.3,  0.50, 1.0) * vec3(2.2, 0.4, 2.5) * 0.05 +
			BaseLens(lightPos, 0.3,  0.70, 1.0) * vec3(1.8, 0.4, 2.5) * 0.06 +
			BaseLens(lightPos, 0.3,  0.95, 1.0) * vec3(0.1, 0.2, 2.5) * 0.10 +
			
			OverlapLens(lightPos, 0.18, -0.30, -0.41) * vec3(2.5, 1.2, 0.1) * 0.010 +
			OverlapLens(lightPos, 0.16, -0.18, -0.29) * vec3(2.5, 0.5, 0.1) * 0.020 +
			OverlapLens(lightPos, 0.15,  0.06,  0.19) * vec3(2.5, 0.2, 0.1) * 0.015 +
			OverlapLens(lightPos, 0.14,  0.15,  0.28) * vec3(1.8, 0.1, 1.2) * 0.015 +
			OverlapLens(lightPos, 0.16,  0.24,  0.37) * vec3(1.0, 0.1, 2.5) * 0.015 +
				
			PointLens(lightPos, 0.03, -0.55) * vec3(2.5, 1.6, 0.0) * 0.20 +
			PointLens(lightPos, 0.02, -0.40) * vec3(2.5, 1.0, 0.0) * 0.15 +
			PointLens(lightPos, 0.04,  0.43) * vec3(2.5, 0.6, 0.6) * 0.20 +
			PointLens(lightPos, 0.02,  0.60) * vec3(0.2, 0.6, 2.5) * 0.15 +
			PointLens(lightPos, 0.03,  0.67) * vec3(0.2, 1.6, 2.5) * 0.25 +
				
			RingLens(lightPos, 0.25, 0.43, 0.45) * vec3(0.10, 0.35, 2.50) * 1.5 +
			RingLens(lightPos, 0.18, 0.98, 0.99) * vec3(0.15, 1.00, 2.55) * 2.5
		) * (falloffIn - falloffOut) + (
			AnamorphicLens(lightPos, 1.0, -1.0) * vec3(0.3,0.7,1.0) * 0.35 +
			RainbowLens(lightPos, 0.525, -1.0, 0.2) * 0.05 +
			RainbowLens(lightPos, 2.0, 4.0, 0.1) * 0.05
		) * (1.0 - falloffOut);

		lensFlare = LensTint(lensFlare, truePos);

		color = mix(color, vec3(1.0), lensFlare * multiplier * multiplier);
	}
}