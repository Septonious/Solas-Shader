#ifdef STARS
float GetNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

void getStars(inout vec3 color, in vec3 worldPos, in float VoU, in float nebulaFactor, in float blackHoleFactor) {
	#ifdef OVERWORLD
	float visibility = (1.0 - sunVisibility) * (1.0 - rainStrength) * (0.5 + nebulaFactor * 0.5);
	#else
	float visibility = 0.5 + nebulaFactor * 0.5;
	#endif

	if (visibility > 0.0) {
		vec2 planeCoord = worldPos.xz / (length(worldPos.y) + length(worldPos.xz));
			 planeCoord+= frameTimeCounter * 0.001 * (1.0 + blackHoleFactor * 100.0);
			 planeCoord+= cameraPosition.xz * 0.0001;
			 planeCoord = floor(planeCoord * 256.0) / 512.0;

		float star = GetNoise(planeCoord.xy);
			  star*= GetNoise(planeCoord.xy + 0.25);

		star = clamp(star - (0.875 - nebulaFactor * 0.125), 0.0, 1.0) * visibility;
		
		color += vec3(32.0 * (1.0 + pow4(star))) * pow2(star);
	}
}
#endif

#ifdef NEBULA
void getNebula(inout vec3 color, in vec3 worldPos, in float VoU, inout float nebulaFactor) {
	#ifdef OVERWORLD
	float visibility = (1.0 - sunVisibility) * 0.5 * (1.0 - rainStrength) * max(VoU, 0.0);
	#else
	float visibility = 1.0 - abs(VoU);
	#endif

	if (visibility > 0.0) {
		#ifdef OVERWORLD
		vec2 planeCoord = worldPos.xz / (worldPos.y + length(worldPos));
		#else
		vec2 planeCoord = worldPos.xz / length(worldPos);
		#endif
			 planeCoord+= frameTimeCounter * 0.01;
			 planeCoord+= cameraPosition.xz * 0.001;
			 #ifdef OVERWORLD
			 planeCoord *= 2.5;
			 #endif

		float nebulaNoise  = texture2D(noisetex, planeCoord * 0.005).r;
			  nebulaNoise -= texture2D(noisetex, planeCoord * 0.050).g * 0.08;
			  nebulaNoise -= texture2D(noisetex, planeCoord * 0.125).b * 0.04;
			  nebulaNoise = max(nebulaNoise, 0.0);

		#ifdef OVERWORLD
		color += lightNight * visibility * (nebulaNoise + pow2(nebulaNoise) * 2.0) * 0.5;
		#else
		color += mix(mix(endAmbientCol, endAmbientColSqrt, pow2(nebulaNoise)), vec3(0.5, 0.25, 0.2) * endLightColSqrt, pow4(nebulaNoise)) * visibility * nebulaNoise;
		#endif

		nebulaFactor = nebulaNoise * visibility;
	}
}
#endif

#ifdef RAINBOW
void getRainbow(inout vec3 color, in vec3 worldPos, in float VoU, in float size, in float rad) {
	float visibility = pow2(sunVisibility) * (1.0 - rainStrength) * wetness * 0.75 * pow2(max(VoU, 0.0));

	if (visibility > 0.0) {
		vec2 planeCoord = worldPos.xy / (worldPos.y + length(worldPos.xz) * 0.65);
		vec2 rainbowCoord = vec2(planeCoord.x + 2.5, planeCoord.y);

		float rainbowFactor = clamp(1.0 - length(rainbowCoord) / size, 0.0, 1.0);
		
		vec3 rainbow = 
			(smoothstep(0.0, rad, rainbowFactor) - smoothstep(rad, rad * 2.0, rainbowFactor)) * vec3(0.5, 0.0, 0.0) +
			(smoothstep(rad * 0.5, rad * 1.5, rainbowFactor) - smoothstep(rad * 1.5, rad * 2.5, rainbowFactor)) * vec3(0.0, 0.5, 0.0) +
			(smoothstep(rad, rad * 2.0, rainbowFactor) - smoothstep(rad * 2.0, rad * 3.0, rainbowFactor)) * vec3(0.0, 0.0, 0.5)
		;

		color += rainbow * visibility;
	}
}
#endif

#ifdef AURORA
float getAuroraNoise(vec2 coord) {
	float noise = texture2D(noisetex, coord * 0.02).b * 3.0;
		  noise+= texture2D(noisetex, coord * 0.01).b * 3.0;

	return max(abs(noise) - 2.5, 0.0);
}

void getAurora(inout vec3 color, in vec3 worldPos) {
	float visibility = (1.0 - sunVisibility) * (1.0 - rainStrength);

	#ifdef AURORA_FULL_MOON_VISIBILITY
	visibility *= float(moonPhase == 0);
	#endif

	#ifdef AURORA_COLD_BIOME_VISIBILITY
	visibility *= isSnowy;
	#endif

	if (visibility > 0.0) {
		vec3 aurora = vec3(0.0);
		
		float dither = Bayer64(gl_FragCoord.xy);

		#ifdef TAA
		dither = fract(dither + frameTimeCounter * 16.0);
		#endif

		int samples = 6;
		float sampleStep = 1.0 / samples;
		float currentStep = dither * sampleStep;

		for(int i = 0; i < samples; i++) {
			vec3 planeCoord = worldPos * ((6.0 + currentStep * 12.0) / worldPos.y) * 0.025;

			vec2 coord = cameraPosition.xz * 0.00005 + planeCoord.xz;
				 coord += vec2(coord.y, -coord.x) * 0.5;

			float noise = getAuroraNoise(coord);
			
			if (noise > 0.0) {
				noise *= texture2D(noisetex, coord * 0.125 + frameTimeCounter * 0.000125).b * 0.5 + 0.5;
				noise *= texture2D(noisetex, coord * 0.500 + frameTimeCounter * 0.002500).b * 0.3 + 0.7;
				noise = pow2(noise) * sampleStep;
				noise *= max(1.0 - length(planeCoord.xz) * 0.25, 0.0);

				vec3 auroraColor = mix(auroraLowCol, auroraHighCol, pow(currentStep, 0.5));
				aurora += noise * auroraColor * exp2(-6.0 * i * sampleStep);
			}
			currentStep += sampleStep;
		}

		color += aurora * visibility;
	}
}
#endif