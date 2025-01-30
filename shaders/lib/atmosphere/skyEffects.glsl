float getSpiralWarping(vec2 coord){
	float whirl = END_VORTEX_WHIRL;
	float arms = END_VORTEX_ARMS;

    coord = vec2(atan(coord.y, coord.x) + frameTimeCounter * 0.05, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow8(1.0 - coord.y) * 24.0;
    float spiral = sin((coord.x + sqrt(coord.y) * whirl) * arms) + center - coord.y;

    return clamp(spiral * 0.1, 0.0, 1.0);
}

#if defined STARS || defined END_STARS
float getNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

void drawStars(inout vec3 color, in vec3 worldPos, in vec3 sunVec, inout vec3 stars, in float VoU, in float caveFactor, in float nebulaFactor, in float volumetricClouds, float size) {
	#ifdef OVERWORLD
	float visibility = mix(0.5, 0.5 - timeBrightnessSqrt * 0.5, sunVisibility) * (1.0 - wetness) * (1.0 - volumetricClouds) * pow(VoU, 0.5) * caveFactor;
	#else
	float visibility = 0.4 - nebulaFactor * 0.2;
	#endif

	if (visibility > 0.0) {
		vec2 planeCoord = worldPos.xz / (length(worldPos.y) + length(worldPos.xz));
			 planeCoord *= size;
			 planeCoord += cameraPosition.xz * 0.00001;
			 planeCoord += frameTimeCounter * 0.0001;
			 planeCoord = floor(planeCoord * 1024.0 * STAR_AMOUNT) / (1024.0 * STAR_AMOUNT);
			 #ifdef END
			 vec3 sunVec = mat3(gbufferModelViewInverse) * sunVec;
			 vec2 sunCoord = sunVec.xz / (sunVec.y + length(sunVec));
			 vec2 planeCoord2 = worldPos.xz / (length(worldPos) + worldPos.y) - sunCoord;
			 float spiral1 = getSpiralWarping(planeCoord2) * clamp(VoU, 0.0, 1.0);
			 planeCoord += spiral1 * 0.000025;
			 #endif

		float star = getNoise(planeCoord);
			  star*= getNoise(planeCoord + 0.25);
			  star*= getNoise(planeCoord + 0.50);
			  star = clamp(star - (0.75 - nebulaFactor * 0.1), 0.0, 1.0);

		stars = vec3(star * visibility * STAR_BRIGHTNESS * 16.0);
		stars *= stars;

		#ifdef OVERWORLD
		stars *= lightNight;
		#else
		stars *= endLightColSqrt * 0.5;
		#endif

		color += stars;
	}
}
#endif

#ifdef MILKY_WAY
void drawMilkyWay(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor, inout float nebulaFactor, in float volumetricClouds) {
	float visibility = (1.0 - timeBrightnessSqrt) * (1.0 - wetness) * (1.0 - volumetricClouds) * sqrt(max(VoU, 0.0)) * MILKY_WAY_BRIGHTNESS * caveFactor;

	if (visibility > 0.0) {
		vec2 planeCoord = worldPos.zx / (worldPos.y + length(worldPos.zyx));
			 planeCoord += frameTimeCounter * 0.0001;
			 planeCoord *= 0.8;
			 planeCoord.x *= 1.9;
		
		vec4 milkyWay = texture2D(depthtex2, planeCoord * 0.5 + 0.6);
		color += mix(lightNight, vec3(1.0), 0.25) * milkyWay.rgb * pow6(milkyWay.a) * length(milkyWay.rgb) * visibility;
		nebulaFactor = length(milkyWay.rgb);
	}
}
#endif

#ifdef END_NEBULA
void getEndNebula(inout vec3 color, inout vec3 color2, in vec3 worldPos, in float VoU, inout float nebulaFactor, in float caveFactor) {
	float visibility = pow(1.0 - abs(VoU), 1.5) * END_NEBULA_BRIGHTNESS;

	if (visibility > 0.0) {
		vec3 sunVec = mat3(gbufferModelViewInverse) * sunVec;
		vec2 sunCoord = sunVec.xz / (sunVec.y + length(sunVec));
		vec2 planeCoord1 = worldPos.xz / (length(worldPos) + worldPos.y) - sunCoord;
		vec2 planeCoord2 = worldPos.xz / length(worldPos) - sunCoord;
		float spiral1 = getSpiralWarping(planeCoord1) * clamp(VoU, 0.0, 1.0);
		float spiral2 = getSpiralWarping(planeCoord2) * clamp(VoU, 0.0, 1.0);
			 planeCoord1 += cameraPosition.xz * 0.0001;
			 planeCoord2 += cameraPosition.xz * 0.0001;
			 planeCoord1 += spiral1 * 0.5;
			 planeCoord2 += spiral2;

		float nebulaNoise1  = texture2D(noisetex, planeCoord1 * 0.01 + frameTimeCounter * 0.0001).r;
			  nebulaNoise1 += texture2D(noisetex, planeCoord1 * 0.02 - frameTimeCounter * 0.0002).r * 0.500;
			  nebulaNoise1 += texture2D(noisetex, planeCoord1 * 0.04 + frameTimeCounter * 0.0003).r * 0.250;
			  nebulaNoise1 += texture2D(noisetex, planeCoord1 * 0.08 - frameTimeCounter * 0.0004).r * 0.250;
			  nebulaNoise1 += texture2D(noisetex, planeCoord1 * 0.16 + frameTimeCounter * 0.0005).r * 0.125;
			  nebulaNoise1 = clamp(nebulaNoise1 - 0.7, 0.0, 1.0);
		float nebulaNoise2  = texture2D(noisetex, planeCoord2 * 0.02 - frameTimeCounter * 0.00015).r;
			  nebulaNoise2 += texture2D(noisetex, planeCoord2 * 0.04 + frameTimeCounter * 0.00030).r * 0.75;
			  nebulaNoise2 += texture2D(noisetex, planeCoord2 * 0.08 - frameTimeCounter * 0.00060).r * 0.50;
			  nebulaNoise2 = clamp(nebulaNoise2 - 0.8, 0.0, 1.0);

		vec3 result = mix(mix(endAmbientCol, endLightCol, nebulaNoise1), mix(vec3(2.0, 0.8, 0.2), vec3(0.1, 2.1, 0.8), nebulaNoise1), texture2D(noisetex, planeCoord1 * 0.025).r * 0.3) * visibility * nebulaNoise1;
			 result += mix(vec3(2.3, 0.8, 0.5), vec3(1.2, 2.2, 0.9), nebulaNoise2 - 0.25) * visibility * pow2(nebulaNoise2) * 0.15;
		color += result;
		color2 += result;
		nebulaFactor = (nebulaNoise1 + nebulaNoise2) * visibility;
	}
}
#endif

#ifdef END_VORTEX
vec3 getSpiral(vec2 coord, float hole) {
	float whirl = END_VORTEX_WHIRL * mix(1.0, 3.0, pow4(hole));
	float arms = END_VORTEX_ARMS;

    coord = vec2(atan(coord.y, coord.x) - frameTimeCounter * 0.125, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow8(1.0 - coord.y) * 24.0;
    float spiral = sin((coord.x + sqrt(coord.y) * whirl) * arms) + center - coord.y;

    return clamp(endAmbientColSqrt * spiral * 0.15, 0.0, 1.0);
}

void getEndVortex(inout vec3 color, in vec3 worldPos, in vec3 stars, in float VoU, in float VoS) {
	if (VoS > 0.5) {
		vec3 sunVec = mat3(gbufferModelViewInverse) * sunVec;
		vec2 sunCoord = sunVec.xz / (sunVec.y + length(sunVec));
		vec2 planeCoord0 = worldPos.xz / (worldPos.y + length(worldPos)) + sunCoord;
			 planeCoord0.x += 0.5;
			 planeCoord0.y -= 0.23;
		vec2 planeCoord1 = worldPos.xz / (worldPos.y + length(worldPos)) - sunCoord;
		vec2 center = vec2(0.5);
		
		float dist = distance(planeCoord0, center);
		float invDist = 1.0 - dist;
		float ring = pow(smoothstep(0.3, 0.05, dist * 1.5) * 4.0, 3.5) + 1.0;

		float hole = step(0.05, dist);
			  hole *= smoothstep(0.085, 0.100, dist);

		vec3 accretionDisk = endLightCol * pow7(invDist) * 0.25;
		vec3 spiral = getSpiral(planeCoord1, VoS);

		color = mix(color, spiral, length(spiral));
		color += clamp(ring * hole * accretionDisk, 0.0, 1.0);
		color *= mix(1.0, 0.0, float(VoS > 0.97) * (1.0 - hole));
	}
}
#endif

#ifdef AURORA
float getAuroraNoise(vec2 coord) {
	float noise = texture2D(noisetex, coord * 0.0050 + frameTimeCounter * 0.00004).b * 3.0;
		  noise+= texture2D(noisetex, coord * 0.0025 - frameTimeCounter * 0.00008).b * 3.0;

	return max(1.0 - 2.0 * abs(noise - 3.0), 0.0);
}

void drawAurora(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor, in float volumetricClouds) {
	float visibilityMultiplier = pow6(1.0 - sunVisibility) * (1.0 - wetness) * (1.0 - volumetricClouds) * caveFactor * AURORA_BRIGHTNESS;
	float visibility = 0.0;

	#ifdef OVERWORLD
	#ifdef AURORA_FULL_MOON_VISIBILITY
	visibility = mix(visibility, 1.0, float(moonPhase == 0));
	#endif

	#ifdef AURORA_COLD_BIOME_VISIBILITY
	visibility = mix(visibility, 1.0, isSnowy);
	#endif
	#endif

    #ifdef AURORA_ALWAYS_VISIBLE
    visibility = 1.0;
    #endif

	visibility *= visibilityMultiplier;

	if (visibility > 0.0) {
		vec3 aurora = vec3(0.0);

        float dither = Bayer8(gl_FragCoord.xy);

        #ifdef TAA
        dither = fract(frameTimeCounter * 16.0 + dither);
        #endif

		int samples = 8;
		float sampleStep = 1.0 / samples;
		float currentStep = dither * sampleStep;

		float pulse = sin(frameTimeCounter);

		for (int i = 0; i < samples; i++) {
			vec3 planeCoord = worldPos * ((14.0 + currentStep * 14.0 - clamp(cameraPosition.y * 0.001, 0.0, 9.0)) / worldPos.y) * 0.025;
				 planeCoord.xy *= 0.75;
			vec2 offsetNoiseCoord = planeCoord.xz + cameraPosition.xz * 0.00005;
				 planeCoord *= 0.5 + texture2D(noisetex, (offsetNoiseCoord + frameTimeCounter * 0.0001) * 0.05).r * 0.5;
			vec2 coord = planeCoord.xz + cameraPosition.xz * 0.0001;

			float noise = getAuroraNoise(coord + frameTimeCounter * 0.0008);
			float noiseBase = noise;
			
			if (noise > 0.0) {
				float auroraDistanceFactor = max(1.0 - length(planeCoord.xz) * 0.25, 0.0);

				noise *= texture2D(noisetex, coord * 0.125 + frameTimeCounter * 0.0008).b * (0.4 - pulse * 0.1) + (0.6 + pulse * 0.1);
				noise *= texture2D(noisetex, coord * 0.250 - frameTimeCounter * 0.0010).b * (0.5 - pulse * 0.2) + (0.5 + pulse * 0.2);
				noise *= noise * sampleStep * auroraDistanceFactor;
				noiseBase *= sampleStep * auroraDistanceFactor;

				float colorMixer = clamp(texture2D(noisetex, coord * 0.0025).b * 1.5, 0.0, 1.0);

				vec3 auroraColor1 = mix(vec3(0.6, 4.0, 0.4), vec3(3.4, 0.1, 1.5), pow(currentStep, 0.25));
					 auroraColor1 *= exp2(-3.0 * i * sampleStep);
				vec3 auroraColor2 = mix(vec3(0.3, 4.0, 0.7), vec3(1.9, 0.4, 3.7), pow(currentStep, 0.50));
					 auroraColor2 *= exp2(-4.5 * i * sampleStep);

				vec3 auroraColor = mix(auroraColor1, auroraColor2, pow3(colorMixer));
				vec3 auroraBlurredColor = auroraColor * noiseBase;
					 auroraColor *= noise;
					 auroraColor *= 1.0 + length(auroraColor);
				aurora += (auroraBlurredColor * (0.4 - pulse * 0.2) + auroraColor * (0.7 + pulse * 0.3));
			}

			currentStep += sampleStep;
		}

		color += aurora * visibility * (1.0 - clamp(pow(VoU, 0.6), 0.0, 0.7));
	}
}
#endif

#ifdef PLANAR_CLOUDS
float samplePlanarCloudNoise(in vec2 coord) {
    float noise = texture2D(noisetex, coord * 0.0625).r * 15.0;
          noise = mix(noise, texture2D(noisetex, coord).r * 2.0, 0.33);
          noise = max(noise - 6.0, 0.0);
          noise /= sqrt(noise * noise + 0.25);
          noise = clamp(noise, 0.0, 1.0);
    return noise;
}

void drawPlanarClouds(inout vec3 color, in vec3 atmosphereColor, in vec3 worldPos, in vec3 viewPos, in float VoU, in float caveFactor, in float volumetricClouds, inout float pc) {
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

    float VoL = clamp(dot(normalize(viewPos), lightVec), 0.0, 1.0) * shadowFade;
    float cloudHeightFactor = pow2(max(1.0 - 0.00025 * cameraPosition.y, 0.0));

    //Sampling
	vec3 planeCoord = worldPos * (cloudHeightFactor / worldPos.y) * 0.2;
         planeCoord.x *= 2.00;
         planeCoord.z *= 0.75;
	vec2 coord = cameraPosition.xz * 0.0001 + planeCoord.xz + frameTimeCounter * 0.001;

    float noise = samplePlanarCloudNoise(coord);
    float lightingNoise = samplePlanarCloudNoise(coord + normalize(ToWorld(lightVec * 10000.0)).xy * 0.1);

    //Lighting and coloring
	#ifdef AURORA
	float visibilityMultiplier = pow8(1.0 - sunVisibility) * (1.0 - wetness) * caveFactor * AURORA_BRIGHTNESS;
	float auroraVisibility = 0.0;

	#ifdef AURORA_FULL_MOON_VISIBILITY
	auroraVisibility = mix(auroraVisibility, 1.0, float(moonPhase == 0));
	#endif

	#ifdef AURORA_COLD_BIOME_VISIBILITY
	auroraVisibility = mix(auroraVisibility, 1.0, isSnowy);
	#endif

	#ifdef AURORA_ALWAYS_VISIBLE
	auroraVisibility = 1.0;
	#endif

	auroraVisibility *= visibilityMultiplier;
	#endif

	pc = noise * VoU * pow(length(planeCoord.y), 0.125) * (1.0 - wetness) * (1.0 - volumetricClouds) * caveFactor;

    float noiseDifference = noise - lightingNoise;
    float morningEveningFactor = mix(1.0, 0.66, sqrt(sunVisibility) * (1.0 - timeBrightnessSqrt));
	float cloudLighting = min(mix(noise * noise, lightingNoise, 0.25), 1.0);

	vec3 cloudAmbientColor = mix(ambientCol, atmosphereColor * atmosphereColor, 0.5 * sunVisibility);
         cloudAmbientColor *= 0.25 + sunVisibility * sunVisibility * (0.2 - wetness * 0.2);
	vec3 cloudLightColor = mix(lightCol, mix(lightCol, atmosphereColor, 0.5 * sunVisibility) * atmosphereColor * 2.0, sunVisibility * (1.0 - timeBrightness * 0.33));
         cloudLightColor *= morningEveningFactor * (2.0 + pow8(VoL) * 4.0);

    vec3 cloudColor = mix(cloudLightColor, cloudAmbientColor, cloudLighting);
         cloudColor = pow(cloudColor, vec3(1.0 / 2.2));
		 #ifdef AURORA
		 cloudColor = mix(cloudColor, vec3(0.4, 2.5, 0.9) * auroraVisibility, auroraVisibility * 0.05);
		 #endif

    color = mix(color, cloudColor * PLANAR_CLOUDS_BRIGHTNESS, pc * PLANAR_CLOUDS_OPACITY);
}
#endif

#ifdef RAINBOW
void getRainbow(inout vec3 color, in vec3 worldPos, in float VoU, in float size, in float radius, in float caveFactor) {
	float visibility = pow3(sunVisibility) * (1.0 - rainStrength) * (1.0 - isSnowy) * wetness * max(VoU, 0.0) * caveFactor * RAINBOW_BRIGHTNESS;

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