#if defined STARS || defined END_STARS
float GetNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

void getStars(inout vec3 color, in vec3 worldPos, in float VoU, in float nebulaFactor, in float caveFactor, inout float star) {
	#ifdef OVERWORLD
	float visibility = (1.0 - timeBrightnessSqrt) * (1.0 - rainStrength) * pow(VoU, 0.125) * caveFactor;
	#else
	float visibility = 0.75 + nebulaFactor * 0.25;
	#endif

	if (visibility > 0.0) {
		vec2 planeCoord = worldPos.xz / (length(worldPos.y) + length(worldPos.xz));
			 planeCoord += frameTimeCounter * 0.001;
			 planeCoord += cameraPosition.xz * 0.0001;
			 planeCoord = floor(planeCoord * 384.0) / 384.0;

	    star = GetNoise(planeCoord.xy);
		star *= GetNoise(planeCoord.xy + 0.1);
		star *= GetNoise(planeCoord.xy + 0.2);
		star = max(star - (0.8 - nebulaFactor * 0.1), 0.0) * visibility;

		color += star * star * 64.0;
	}
}
#endif

#ifdef END_VORTEX
vec3 getSpiral(vec2 coord, float VoS){
    coord = vec2(atan(coord.y, coord.x) - frameTimeCounter * 0.125, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow32(1.0 - coord.y) * 32.0;
    float spiral = sin((coord.x + sqrt(coord.y) * END_VORTEX_WHIRL) * END_VORTEX_ARMS) + center - coord.y;

    return clamp(endAmbientColSqrt * spiral * 0.25, 0.0, 1.0);
}

void getEndVortex(inout vec3 color, in vec3 worldPos, in float VoU, in float VoS, inout float endVortex) {
	if (VoS > 0.0) {
		vec3 sunVec = mat3(gbufferModelViewInverse) * sunVec;
		vec2 sunCoord = sunVec.xz / (sunVec.y + length(sunVec));
		vec2 planeCoord = worldPos.xz / (worldPos.y + length(worldPos)) - sunCoord;
		vec3 spiral = getSpiral(planeCoord, VoS);
		
		float spiralBrightness = length(spiral);
		float hole = pow16(pow32(VoS));

		color = mix(color, spiral * END_VORTEX_SIZE, pow3(spiralBrightness));
		color *= int(length(hole) < 0.5);
		endVortex = mix(0.0, length(spiral * END_VORTEX_SIZE), pow3(spiralBrightness));
		endVortex *= int(length(hole) < 0.5);
	}
}
#endif

#if (defined MILKY_WAY && !defined GBUFFERS_WATER) || defined END_NEBULA
void getNebula(inout vec3 color, in vec3 worldPos, in float VoU, inout float nebulaFactor, in float caveFactor) {
	#ifdef OVERWORLD
	float visibility = (1.0 - timeBrightnessSqrt) * (1.0 - rainStrength) * sqrt(max(VoU, 0.0)) * MILKY_WAY_BRIGHTNESS * caveFactor;
	#else
	float visibility = 1.0 - abs(VoU);
	#endif

	if (visibility > 0.0) {
		#ifdef OVERWORLD
		vec2 planeCoord = worldPos.xz / (worldPos.y + length(worldPos));
		#else
		vec2 planeCoord = worldPos.xz / length(worldPos);
		#endif
			 planeCoord+= cameraPosition.xz * 0.0001;
			 planeCoord+= frameTimeCounter * 0.0001;

		#ifdef END
		float nebulaNoise  = texture2D(noisetex, planeCoord * 0.005).r;
			  nebulaNoise -= texture2D(noisetex, planeCoord * 0.050).g * 0.08;
			  nebulaNoise -= texture2D(noisetex, planeCoord * 0.125).b * 0.04;
			  nebulaNoise = max(nebulaNoise, 0.0);
		#endif

		#ifdef OVERWORLD
		planeCoord *= 0.75;
		planeCoord.y += 0.4;
		planeCoord.x *= 1.6;
		vec4 milkyWay = texture2D(depthtex2, planeCoord * 0.5 + 0.5);
		color += lightNight * milkyWay.rgb * pow6(milkyWay.a) * length(milkyWay.rgb) * visibility;
		#else
		color += mix(mix(endAmbientCol, endAmbientColSqrt, nebulaNoise * nebulaNoise), vec3(0.5, 0.25, 0.2) * endLightColSqrt, pow4(nebulaNoise)) * visibility * nebulaNoise * 2.0;
		#endif

		#ifdef OVERWORLD
		nebulaFactor = length(milkyWay.rgb);
		#else
		nebulaFactor = nebulaNoise * visibility;
		#endif
	}
}
#endif

#ifdef RAINBOW
void getRainbow(inout vec3 color, in vec3 worldPos, in float VoU, in float size, in float radius, in float caveFactor) {
	float visibility = sunVisibility * (1.0 - rainStrength) * (1.0 - isSnowy) * wetness * max(VoU, 0.0) * caveFactor;

	if (visibility > 0.0) {
		vec2 planeCoord = worldPos.xy / (worldPos.y + length(worldPos.xz) * 0.65);
		vec2 rainbowCoord = vec2(planeCoord.x + 2.5, planeCoord.y);

		float rainbowFactor = clamp(1.0 - length(rainbowCoord) / size, 0.0, 1.0);
		
		vec3 rainbow = 
			(smoothstep(0.0, radius, rainbowFactor) - smoothstep(radius, radius * 2.0, rainbowFactor)) * vec3(0.5, 0.0, 0.0) +
			(smoothstep(radius * 0.5, radius * 1.5, rainbowFactor) - smoothstep(radius * 1.5, radius * 2.5, rainbowFactor)) * vec3(0.0, 0.5, 0.0) +
			(smoothstep(radius, radius * 2.0, rainbowFactor) - smoothstep(radius * 2.0, radius * 3.0, rainbowFactor)) * vec3(0.0, 0.0, 0.5)
		;

		color += rainbow * visibility;
	}
}
#endif

#ifdef AURORA
float getAuroraNoise(vec2 coord) {
	float noise = texture2D(noisetex, coord * 0.006).b * 3.0;
		  noise+= texture2D(noisetex, coord * 0.003).b * 3.0;

	return max(1.0 - 2.0 * abs(noise - 3.0), 0.0);
}

void getAurora(inout vec3 color, in vec3 worldPos, in float caveFactor) {
	float visibility = pow6(1.0 - sunVisibility) * (1.0 - rainStrength) * caveFactor;

	#ifdef AURORA_FULL_MOON_VISIBILITY
	visibility *= int(moonPhase == 0);
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

		int samples = 10;
		float sampleStep = 1.0 / samples;
		float currentStep = dither * sampleStep;

		for (int i = 0; i < samples; i++) {
			vec3 planeCoord = worldPos * ((10.0 + currentStep * 20.0) / worldPos.y) * 0.04;
			vec2 coord = cameraPosition.xz * 0.00005 + planeCoord.xz;

			float noise = getAuroraNoise(coord + frameTimeCounter * 0.001);
			
			if (noise > 0.0) {
				noise *= texture2D(noisetex, coord * 0.125 + frameTimeCounter * 0.002).g * 0.5 + 0.5;
				noise *= texture2D(noisetex, coord * 0.250 + frameTimeCounter * 0.003).b * 0.5 + 0.5;
				noise *= noise * sampleStep;
				noise *= max(1.0 - length(planeCoord.xz) * 0.175, 0.0);

				float noiseColorMixer = texture2D(noisetex, coord * 0.001).r;
					  noiseColorMixer *= noiseColorMixer;
				vec3 auroraColor1 = mix(vec3(0.6, 0.9, 2.0), vec3(2.0, 0.4, 0.9), pow(currentStep, 0.5)) * 4.0;
				vec3 auroraColor2 = mix(vec3(1.0, 3.0, 2.1) * vec3(1.0, 3.0, 2.1), vec3(1.07, 1.3, 2.75) * vec3(1.07, 1.3, 2.75), pow(currentStep, 0.5));
				vec3 auroraColor = mix(auroraColor1, auroraColor2, noiseColorMixer);
				aurora += noise * auroraColor * exp2(-6.0 * i * sampleStep);
			}

			currentStep += sampleStep;
		}

		color += aurora * visibility;
	}
}
#endif