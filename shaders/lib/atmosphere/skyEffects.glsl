#ifdef STARS
float GetNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

void getStars(inout vec3 color, in vec3 worldPos, in float nebulaFactor) {
	vec3 planeCoord = worldPos.xyz / (worldPos.y + length(worldPos.xz));

	vec2 coord = planeCoord.xz * 0.5 + cameraPosition.xz * 0.000001 + (frameTimeCounter * 0.25) * 0.001;
		 coord = floor(coord * 1024.0) / 1024.0;

	float multiplier = (0.75 + moonVisibility + 0.25) * (1.0 - rainStrength) * (0.25 + nebulaFactor);

	float star  = GetNoise(coord.xy);
		  star *= GetNoise(coord.xy + 0.2);

	star = clamp(star - 0.875, 0.0, 1.0) * multiplier;
    
    color.rgb += vec3(1.0) * star;
}
#endif

#ifdef NEBULA
void getNebula(inout vec3 color, in vec3 worldPos, in vec3 viewPos, in float VoU, inout float nebulaFactor) {
	float visibility = (1.0 - rainStrength) * (1.5 - sunVisibility) * max(VoU, 0.0);

	vec2 wind = vec2(frameTimeCounter, 0.0);
	vec2 planeCoord = worldPos.xz / (worldPos.y + length(worldPos.xz) * 0.25) * 0.25 + wind * 0.001;
		 planeCoord += cameraPosition.xz * 0.00001;

	float nebulaNoise  = texture2D(noisetex, planeCoord * 0.04).r * 0.8;
		  nebulaNoise -= texture2D(noisetex, planeCoord * 0.08).r * 0.4;
		  nebulaNoise -= texture2D(noisetex, planeCoord * 0.32).r * 0.2;
		  nebulaNoise = clamp(nebulaNoise, 0.0, 1.0);

	color.rgb += nebulaNoise * lightNight * lightNight * visibility;
	nebulaFactor = nebulaNoise;
}
#endif

#ifdef RAINBOW
void getRainbow(inout vec3 color, in vec3 worldPos, in vec3 viewPos, in float VoU, in float size, in float rad) {
	vec3 planeCoord = worldPos / (worldPos.y + length(worldPos.xz) * 0.5);
	vec2 rainbowCoord = planeCoord.xz + vec2(2.5, 0.0);

	float rainbowFactor = clamp(1.0 - length(rainbowCoord) / size, 0.0, 1.0);
	
	vec3 rainbow = 
		(smoothstep(0.0, rad, rainbowFactor) - smoothstep(rad, rad * 2.0, rainbowFactor)) * vec3(1.0, 0.0, 0.0) +
		(smoothstep(rad * 0.5, rad * 1.5, rainbowFactor) - smoothstep(rad * 1.5, rad * 2.5, rainbowFactor)) * vec3(0.0, 1.0, 0.0) +
		(smoothstep(rad, rad * 2.0, rainbowFactor) - smoothstep(rad * 2.0, rad * 3.0, rainbowFactor)) * vec3(0.0, 0.0, 1.0)
	;

	color += rainbow * max(VoU, 0.0) * wetness * (1.0 - pow(rainStrength, 0.25)) * timeBrightness * 0.5;
}
#endif

#ifdef AURORA
#include "/lib/color/auroraColor.glsl"

float getAuroraNoise(vec2 coord, vec2 wind) {
	float noise = texture2D(noisetex, coord * 0.030 + wind * 0.25).b * 3.0;
		  noise+= texture2D(noisetex, coord * 0.015 + wind * 0.15).b * 3.0;

	noise = max(1.0 - 2.0 * abs(noise - 3.0), 0.0);

	return noise;
}

void getAurora(inout vec3 color, in vec3 viewPos, in vec3 worldPos) {
	float visibility = moonVisibility * pow2(1.0 - rainStrength);

	#ifdef FOG_PERBIOME
	visibility *= pow2(isCold);
	#endif

	vec3 aurora = vec3(0.0);

	if (visibility > 0.0) {
		float dither = Bayer64(gl_FragCoord.xy);

		#ifdef TAA
		dither = fract(dither + frameTimeCounter * 16.0);
		#endif

		int samples = 14;
		float sampleStep = 1.0 / samples;
		float currentStep = dither * sampleStep;

		vec2 wind = vec2(frameTimeCounter * 0.0001, frameTimeCounter * 0.0002);

		for(int i = 0; i < samples; i++) {
			vec3 planeCoord = worldPos * ((6.0 + currentStep * 16.0) / worldPos.y) * 0.005;

			vec2 coord = cameraPosition.xz * 0.00004 + planeCoord.xz;
				 coord += vec2(coord.y, -coord.x) * 0.5;

			float noise = getAuroraNoise(coord, wind);
			
			if (noise > 0.0) {
				noise *= texture2D(noisetex, coord * 0.125 + wind * 0.25).b;
				noise *= texture2D(noisetex, coord + wind * 16.0).b * 0.5 + 0.75;
				noise = pow2(noise) * 4.0 * sampleStep;
				noise *= max(sqrt(1.0 - length(planeCoord.xz) * 2.0), 0.0);

				vec3 auroraColor = mix(auroraLowCol, auroraHighCol, pow(currentStep, 0.5));
				aurora += noise * auroraColor * exp2(-8.0 * i * sampleStep);
			}
			currentStep += sampleStep;
		}
	}

	color += aurora * visibility;
}
#endif