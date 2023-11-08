#if defined STARS || defined END_STARS
float getNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

void getStars(inout vec3 color, in vec3 worldPos, in float VoU, in float nebulaFactor, in float caveFactor) {
	#ifdef OVERWORLD
	float visibility = mix(0.5, 0.5 - timeBrightnessSqrt * 0.5, sunVisibility) * (1.0 - wetness) * pow(VoU, 0.125) * caveFactor;
	#else
	float visibility = 0.75 + nebulaFactor * 0.25;
	#endif

	if (visibility > 0.0) {
		vec2 planeCoord = worldPos.xz / (length(worldPos.y) + length(worldPos.xz));
			 planeCoord += frameTimeCounter * 0.001;
			 planeCoord += cameraPosition.xz * 0.0001;
			 planeCoord = floor(planeCoord * 384.0) / 384.0;

	    float star = getNoise(planeCoord.xy);
              star *= getNoise(planeCoord.xy + 0.1);
              star = max(star - (0.85 - nebulaFactor * 0.05), 0.0);
			  star *= star * 32.0;

		color += star * visibility;
	}
}
#endif

#if defined MILKY_WAY || defined END_NEBULA
float getSpiralWarping(vec2 coord){
    coord = vec2(atan(coord.y, coord.x) - frameTimeCounter * 0.125, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow4(1.0 - coord.y) * 16.0;
    float spiral = sin((coord.x + sqrt(coord.y) * 10.0) * 6.0) + center - coord.y;

    return clamp(spiral * 0.075, 0.0, 1.0);
}

void getNebula(inout vec3 color, in vec3 worldPos, in float VoU, inout float nebulaFactor, in float caveFactor) {
	#ifdef OVERWORLD
	float visibility = (1.0 - timeBrightnessSqrt) * (1.0 - wetness) * sqrt(max(VoU, 0.0)) * MILKY_WAY_BRIGHTNESS * caveFactor;
	#else
	float visibility = pow2(1.0 - abs(VoU)) * END_NEBULA_BRIGHTNESS;
	#endif

	if (visibility > 0.0) {
		#ifdef OVERWORLD
		vec2 planeCoord = worldPos.xz / (worldPos.y + length(worldPos));
			 planeCoord += cameraPosition.xz * 0.0001;
		#else
		vec3 sunVec = mat3(gbufferModelViewInverse) * sunVec;
		vec2 sunCoord = sunVec.xz / (sunVec.y + length(sunVec));
		vec2 planeCoord1 = worldPos.xz / (length(worldPos) + worldPos.y) - sunCoord;
		vec2 planeCoord2 = worldPos.xz / length(worldPos) - sunCoord;
		float spiral1 = getSpiralWarping(planeCoord1) * clamp(VoU, 0.0, 1.0);
		float spiral2 = getSpiralWarping(planeCoord2) * clamp(VoU, 0.0, 1.0);
			 planeCoord1 += cameraPosition.xz * 0.0001;
			 planeCoord2 += cameraPosition.xz * 0.0001;
			 planeCoord1 += spiral1;
			 planeCoord2 += spiral2 * 2.0;
		#endif

		#ifdef END
		float nebulaNoise1  = texture2D(noisetex, planeCoord1 * 0.01 + frameTimeCounter * 0.0001).r;
			  nebulaNoise1 += texture2D(noisetex, planeCoord1 * 0.02 - frameTimeCounter * 0.0002).r * 0.500;
			  nebulaNoise1 += texture2D(noisetex, planeCoord1 * 0.04 + frameTimeCounter * 0.0003).r * 0.250;
			  nebulaNoise1 += texture2D(noisetex, planeCoord1 * 0.08 - frameTimeCounter * 0.0004).r * 0.250;
			  nebulaNoise1 += texture2D(noisetex, planeCoord1 * 0.16 + frameTimeCounter * 0.0005).r * 0.125;
			  nebulaNoise1 = clamp(nebulaNoise1 - 0.7, 0.0, 1.0);
		float nebulaNoise2  = texture2D(noisetex, planeCoord2 * 0.02 - frameTimeCounter * 0.00015).r;
			  nebulaNoise2 += texture2D(noisetex, planeCoord2 * 0.04 + frameTimeCounter * 0.00030).r * 0.75;
			  nebulaNoise2 += texture2D(noisetex, planeCoord2 * 0.08 - frameTimeCounter * 0.00060).r * 0.50;
			  nebulaNoise2 = clamp(nebulaNoise2 - 0.95, 0.0, 1.0);
		#endif

		#ifdef OVERWORLD
		planeCoord *= 0.75;
		planeCoord.y += 0.4;
		planeCoord.x *= 1.6;
		
		vec4 milkyWay = texture2D(depthtex2, planeCoord * 0.5 + 0.5);
		color += lightNight * milkyWay.rgb * pow6(milkyWay.a) * length(milkyWay.rgb) * visibility;
		nebulaFactor = length(milkyWay.rgb);
		#else
		color += mix(mix(endAmbientCol, endLightCol, nebulaNoise1), mix(vec3(1.9, 1.1, 0.3), vec3(0.7, 2.1, 0.5), nebulaNoise1), texture2D(noisetex, planeCoord1 * 0.025).r * 0.3) * visibility * nebulaNoise1;
		color += mix(vec3(1.9, 0.8, 0.6), vec3(1.2, 2.1, 0.5), sqrt(nebulaNoise2) - 0.25) * visibility * nebulaNoise2 * nebulaNoise2 * 0.25;
		nebulaFactor = (nebulaNoise1 + nebulaNoise2) * visibility;
		#endif
	}
}
#endif

#ifdef AURORA
float getAuroraNoise(vec2 coord) {
	float noise = texture2D(noisetex, coord * 0.0050 + frameTimeCounter * 0.00004).b * 3.0;
		  noise+= texture2D(noisetex, coord * 0.0025 - frameTimeCounter * 0.00008).b * 3.0;

	return max(1.0 - 2.0 * abs(noise - 3.0), 0.0);
}

void getAurora(inout vec3 color, in vec3 worldPos, in float caveFactor, in float dither) {
	float visibilityMultiplier = pow8(1.0 - sunVisibility) * (1.0 - wetness) * caveFactor * AURORA_BRIGHTNESS;
	float visibility = 0.0;

	#ifdef AURORA_FULL_MOON_VISIBILITY
	visibility = mix(visibility, 1.0, float(moonPhase == 0));
	#endif

	#ifdef AURORA_COLD_BIOME_VISIBILITY
	visibility = mix(visibility, 1.0, isSnowy);
	#endif

	visibility *= visibilityMultiplier;

	if (visibility > 0.0) {
		vec3 aurora = vec3(0.0);

		int samples = 8;
		float sampleStep = 1.0 / samples;
		float currentStep = dither * sampleStep;

		for (int i = 0; i < samples; i++) {
			vec3 planeCoord = worldPos * ((10.0 + currentStep * 14.0 - clamp(cameraPosition.y * 0.001, 0.0, 9.0)) / worldPos.y) * 0.025;
			vec2 coord = cameraPosition.xz * 0.00005 + planeCoord.xz;

			float noise = getAuroraNoise(coord + frameTimeCounter * 0.001);
			
			if (noise > 0.0) {
				noise *= texture2D(noisetex, coord * 0.250 - frameTimeCounter * 0.002).b * 0.4 + 0.6;
				noise *= texture2D(noisetex, coord * 0.125 + frameTimeCounter * 0.001).b * 0.4 + 0.6;
				noise *= noise * sampleStep;
				noise *= max(1.0 - length(planeCoord.xz) * 0.2, 0.0);

				float noiseColorMixer = texture2D(noisetex, coord * 0.005).b;
				vec3 auroraColor1 = mix(vec3(0.6, 0.9, 2.0), vec3(2.0, 0.4, 0.9), pow(currentStep, 0.5)) * 6.0;
				vec3 auroraColor2 = mix(vec3(1.0, 3.3, 2.1) * vec3(1.0, 3.3, 2.1), vec3(1.07, 1.3, 2.75) * vec3(1.07, 1.3, 2.75), pow(currentStep, 0.5));
				vec3 auroraColor = mix(auroraColor1, auroraColor2, noiseColorMixer);
				aurora += noise * auroraColor * exp2(-6.0 * i * sampleStep);
			}

			currentStep += sampleStep;
		}

		color += aurora * visibility;
	}
}
#endif

#ifdef END_VORTEX
vec3 getSpiral(vec2 coord){
    coord = vec2(atan(coord.y, coord.x) - frameTimeCounter * 0.125, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow8(1.0 - coord.y) * 24.0;
    float spiral = sin((coord.x + sqrt(coord.y) * END_VORTEX_WHIRL) * END_VORTEX_ARMS) + center - coord.y;

    return clamp(endAmbientColSqrt * spiral * 0.15, 0.0, 1.0);
}

void getEndVortex(inout vec3 color, in vec3 worldPos, in float VoU, in float VoS) {
	if (VoS > 0.0) {
		vec3 sunVec = mat3(gbufferModelViewInverse) * sunVec;
		vec2 sunCoord = sunVec.xz / (sunVec.y + length(sunVec));
		vec2 planeCoord = worldPos.xz / (worldPos.y + length(worldPos)) - sunCoord;
		vec3 spiral = getSpiral(planeCoord);
		
		float spiralBrightness = length(spiral);
		float hole = pow4(pow32(VoS));

		color = mix(color, spiral, pow3(spiralBrightness));
		color *= int(length(hole) < 0.5);
	}
}
#endif

#ifdef RAINBOW
void getRainbow(inout vec3 color, in vec3 worldPos, in float VoU, in float size, in float radius, in float caveFactor) {
	float visibility = sunVisibility * (1.0 - wetness) * (1.0 - isSnowy) * wetness * max(VoU, 0.0) * caveFactor * 4.0;

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