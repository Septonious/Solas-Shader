//Lens flare from BSL & Prismarine Shader, highly modified
float fovmult = gbufferProjection[1][1] / 1.37373871;

float getLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

vec2 getLightPos() {
	vec4 tpos = gbufferProjection * vec4(sunPosition, 1.0);
	tpos.xyz /= tpos.w;
	return tpos.xy / tpos.z * 0.5;
}

float BaseLens(vec2 lightPos, float size, float dist, float hardness) {
	vec2 lensCoord = (texCoord + (lightPos * dist - 0.5)) * vec2(aspectRatio,1.0);
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
	lens = mix(lens, getLuminance(lens) * lightNight * 0.5, isMoon * 0.98);
	return lens * visibility;
}

void LensFlare(inout vec3 color, vec2 lightPos, float truePos, float multiplier) {
	float falloffBase = length(lightPos * vec2(aspectRatio, 1.0));
	float falloffIn = pow(clamp(falloffBase * 10.0, 0.0, 1.0), 2.0);
	float falloffOut = clamp(falloffBase * 3.0 - 1.5, 0.0, 1.0);

	if (falloffOut < 0.999) {
		vec3 lensFlare = (
			#ifdef BASELENS1
			BaseLens(lightPos, 0.3, -0.45, 1.0) * vec3(2.2, 1.2, 0.1) * 0.07 +
			#endif
			#ifdef BASELENS2
			BaseLens(lightPos, 0.3,  0.10, 1.0) * vec3(2.2, 0.4, 0.1) * 0.03 +
			#endif
			#ifdef BASELENS3
			BaseLens(lightPos, 0.3,  0.30, 1.0) * vec3(2.2, 0.2, 0.1) * 0.04 +
			#endif
			#ifdef BASELENS4
			BaseLens(lightPos, 0.3,  0.50, 1.0) * vec3(2.2, 0.4, 2.5) * 0.05 +
			#endif
			#ifdef BASELENS5
			BaseLens(lightPos, 0.3,  0.70, 1.0) * vec3(1.8, 0.4, 2.5) * 0.06 +
			#endif
			#ifdef BASELENS6
			BaseLens(lightPos, 0.3,  0.95, 1.0) * vec3(0.1, 0.2, 2.5) * 0.10 +
			#endif
			
			#ifdef OVERLAPLENS1
			OverlapLens(lightPos, 0.18, -0.30, -0.41) * vec3(2.5, 1.2, 0.1) * 0.110 +
			#endif
			#ifdef OVERLAPLENS2
			OverlapLens(lightPos, 0.16, -0.18, -0.29) * vec3(2.5, 0.5, 0.1) * 0.120 +
			#endif
			#ifdef OVERLAPLENS3
			OverlapLens(lightPos, 0.15,  0.06,  0.19) * vec3(2.5, 0.2, 0.1) * 0.115 +
			#endif
			#ifdef OVERLAPLENS4
			OverlapLens(lightPos, 0.14,  0.15,  0.28) * vec3(1.8, 0.1, 1.2) * 0.115 +
			#endif
			#ifdef OVERLAPLENS5
			OverlapLens(lightPos, 0.16,  0.24,  0.37) * vec3(1.0, 0.1, 2.5) * 0.115 +
			#endif
			
			#ifdef POINT1	
			PointLens(lightPos, 0.03, -0.55) * vec3(2.5, 1.6, 0.0) * 0.20 +
			#endif
			#ifdef POINT2
			PointLens(lightPos, 0.02, -0.40) * vec3(2.5, 1.0, 0.0) * 0.15 +
			#endif
			#ifdef POINT3
			PointLens(lightPos, 0.02, -0.10) * vec3(2.5, 1.0, 4.0) * 0.75 +
			#endif
			#ifdef POINT4
			PointLens(lightPos, 0.02, 0.21) * vec3(0.5, 2.0, 10.0) * 0.25 +
			#endif
			#ifdef POINT5
			PointLens(lightPos, 0.04,  0.43) * vec3(2.5, 0.6, 0.6) * 0.20 +
			#endif
			#ifdef POINT6
			PointLens(lightPos, 0.02,  0.60) * vec3(0.2, 0.6, 2.5) * 0.15 +
			#endif
			#ifdef POINT7
			PointLens(lightPos, 0.03,  0.67) * vec3(0.2, 1.6, 2.5) * 0.25 +
			#endif
			#ifdef POINT8
			PointLens(lightPos, 0.04,  0.62) * vec3(4.2, 1.6, 2.5) * 0.25 +
			#endif
			#ifdef POINT9
			PointLens(lightPos, 0.04,  0.64) * vec3(3.2, 1.6, 2.5) * 0.25 +
			#endif
			#ifdef POINT10
			PointLens(lightPos, 0.04,  0.95) * vec3(13.2, 11.6, 2.5) * 0.25 +
			#endif
			#ifdef POINT11
			PointLens(lightPos, 0.04,  1.04) * vec3(13.2, 5.8, 1.5) * 0.25 +
			#endif
				
			#ifdef RING1
			RingLens(lightPos, 0.25, 0.43, 0.45) * vec3(0.10, 0.35, 2.50) * 1.5 +
			#endif
			#ifdef RING2
			RingLens(lightPos, 0.25, 0.40, 0.42) * vec3(0.10, 5.35, 2.50) * 1.5 +
			#endif
			#ifdef RING3
			RingLens(lightPos, 0.25, 0.37, 0.39) * vec3(5.0, 5.0, 0.00) * 1.5 +
			#endif
			#ifdef RING4
			RingLens(lightPos, 0.25, 0.34, 0.36) * vec3(7.0, 4.0, 0.00) * 1.5 +
			#endif
			#ifdef RING5
			RingLens(lightPos, 0.25, 0.31, 0.33) * vec3(9.0, 0.00, 0.00) * 1.5 +
			#endif
			#ifdef RING6
			RingLens(lightPos, 0.15, 0.30, 0.32) * vec3(0.10, 5.35, 2.50) * 0.5 +
			#endif
			#ifdef RING7
			RingLens(lightPos, 0.15, 0.27, 0.29) * vec3(5.0, 5.0, 0.00) * 0.5 +
			#endif
			#ifdef RING8
			RingLens(lightPos, 0.15, 0.24, 0.26) * vec3(7.0, 4.0, 0.00) * 0.5 +
			#endif
			#ifdef RING9
			RingLens(lightPos, 0.15, 0.21, 0.23) * vec3(9.0, 0.00, 0.00) * 0.5 +
			#endif
			#ifdef RING10
			RingLens(lightPos, 0.18, 0.98, 0.99) * vec3(0.10, 0.35, 2.50) * 2.5 +
			#endif
			#ifdef RING11
			RingLens(lightPos, 0.18, 0.95, 0.96) * vec3(0.10, 5.35, 2.50) * 2.5 +
			#endif
			#ifdef RING12
			RingLens(lightPos, 0.18, 0.92, 0.93) * vec3(5.0, 5.0, 0.00) * 2.5 +
			#endif
			#ifdef RING13
			RingLens(lightPos, 0.18, 0.89, 0.90) * vec3(7.0, 4.0, 0.00) * 2.5 +
			#endif
			#ifdef RING14
			RingLens(lightPos, 0.18, 0.86, 0.87) * vec3(9.0, 0.00, 0.00) * 2.5 +
			#endif
			RingLens(lightPos, 0.18, 0.86, 0.87) * vec3(9.0, 0.00, 0.00) * 0.0
		) * (falloffIn - falloffOut) + (
			#ifdef ANAMORPHICLENS
			#ifdef OVERWORLD
			AnamorphicLens(lightPos, 1.0, -1.0) * vec3(1.0, 1.0, 1.0) * 0.75 +
			#else
			AnamorphicLens(lightPos, 1.0, -1.0) * vec3(3.6, 2.2, 1.2) * 0.5 +
			#endif
			#endif
			#ifdef RAINBOW1
			RainbowLens(lightPos, 0.525, -1.0, 0.2) * 0.29 +
			#endif
			#ifdef RAINBOW2
			RainbowLens(lightPos, 0.225, -1.0, 0.2) * 0.97 +
			#endif
			#ifdef RAINBOW3
			RainbowLens(lightPos, 2.0, 4.0, 0.1) * 0.05 +
			#endif
			RainbowLens(lightPos, 2.0, 4.0, 0.1) * 0.00
		) * (1.0 - falloffOut);

		lensFlare = LensTint(lensFlare, truePos);

		#ifdef END
		lensFlare *= vec3(1.0, 0.9, 0.7) * 2.0;
		#endif

		color = mix(color, vec3(1.0), lensFlare * multiplier * multiplier);
	}
}