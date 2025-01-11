float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

#ifdef VC_SHADOWS
void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float thickness, inout float density, inout float detail, inout float height) {
	float dayAmountFactor = abs(worldDay % 7 / 2 - 0.5) * 0.5;
	float dayDensityFactor = abs(worldDay % 9 / 4 - worldDay % 2);
	float dayFrequencyFactor = 1.0 + abs(worldDay % 6 / 4 - worldDay % 2) * 0.65;

	speed += wetness;
	amount = mix(amount, 11.5, wetness) - dayAmountFactor;
	thickness += dayFrequencyFactor - 0.75;
	density += dayDensityFactor;
	frequency *= dayFrequencyFactor;
}

void getCloudSample(vec2 rayPos, vec2 wind, float amount, float frequency, float thickness, float density, float detail, inout float noise) {
	rayPos *= 0.000125 * frequency;

	float noiseBase = texture2D(noisetex, rayPos + 0.5 + wind * 0.5).g;
		  noiseBase = pow2(1.0 - noiseBase) * 0.5 + 0.4 - wetness * 0.025;

	float detailZ = floor(thickness) * 0.05;
	float noiseDetailA = texture2D(noisetex, rayPos * 1.5 - wind + detailZ).b;
	float noiseDetailB = texture2D(noisetex, rayPos * 1.5 - wind + detailZ + 0.05).b;
	float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(thickness));
	
	noise = mix(noiseBase, noiseDetail, detail * mix(0.05, 0.025, min(wetness + cameraPosition.y * 0.0025, 1.0)) * int(noiseBase > 0.0)) * 22.0;
	noise = max(noise - amount, 0.0) * (density * 0.25);
	noise /= sqrt(noise * noise + 0.25);
	noise = exp((noise * noise) * -100.0);
	
}
#endif

vec3 ToShadowProjected(vec3 pos){
    pos = mat3(gbufferModelViewInverse) * pos + gbufferModelViewInverse[3].xyz;
    pos = mat3(shadowModelView) * pos + shadowModelView[3].xyz;
    pos = diagonal3(shadowProjection) * pos + shadowProjection[3].xyz;

    return pos;
}

vec3 distortShadow(vec3 shadowPos) {
    float distb = sqrt(shadowPos.x * shadowPos.x + shadowPos.y * shadowPos.y);
    float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);

    shadowPos.xy /= distortFactor;
    shadowPos.z *= 0.2;
    shadowPos = shadowPos * 0.5 + 0.5;
    shadowPos.z += 0.0512 / shadowMapResolution;

	return shadowPos;
}

void computeVL(inout vec3 vl, in vec3 translucent, in float dither) {
	vec3 finalVL = vec3(0.0);

	int sampleCount = VL_SAMPLES;

	//Depth
	float z0 = texture2D(depthtex0, texCoord).r;

	//Positions
	vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
	vec3 worldSunVec = mat3(gbufferModelViewInverse) * lightVec;
	vec3 viewPos = ToView(vec3(texCoord.xy, z0));
	vec3 nViewPos = normalize(viewPos);
	vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;
	vec3 shadowPos = mat3(shadowModelView) * worldPos + shadowModelView[3].xyz;
		 shadowPos = diagonal3(shadowProjection) * shadowPos + shadowProjection[3].xyz;

	vec3 startPos = ToShadowProjected(vec3(0.0));
	vec3 sampleStepS = shadowPos - startPos;
	vec3 sampleStepW = worldPos - gbufferModelViewInverse[3].xyz;

	float distanceFactor = 16.0;
	float maxDist = min(length(sampleStepW), 512.0) / length(sampleStepW);
	
	sampleStepS *= maxDist;
	sampleStepW *= maxDist;

	vec3 rayShadowPos = startPos;
	vec3 rayWorldPos = vec3(0.0);

    //Total Visibility & Variables
    float indoorFactor = (1.0 - eBS * eBS) * float(isEyeInWater == 0 && cameraPosition.y < 1000.0);
		#if MC_VERSION >= 12104
		indoorFactor = mix(indoorFactor, 1.0, isPaleGarden * 0.5);
		#endif

	float VoU = clamp(dot(nViewPos, upVec), 0.0, 1.0);
		  VoU = 1.0 - pow(VoU, 1.5);
		  VoU = mix(VoU, 1.0, min(indoorFactor + timeBrightness, 1.0) * 0.75);
	float VoL = clamp(dot(nViewPos, lightVec), 0.0, 1.0);
		  VoL = mix(VoL, 0.5, 0.25 * float(isEyeInWater == 1));

	#ifdef OVERWORLD
	float waterFactor = 1.0 - float(isEyeInWater == 1) * 0.5;
	float denseForestFactor = min(isSwamp + isJungle, 1.0);
	float meVisRatio = VL_STRENGTH_RATIO + pow(VoL, 1.5) * (1.0 - VL_STRENGTH_RATIO);
	float visibility = int(z0 > 0.56) * shadowFade * VL_STRENGTH;
		  visibility *= mix(meVisRatio, mix(0.0, 0.75, pow(VoL, 1.5)) * (2.0 - sunVisibility), clamp(timeBrightness + (1.0 - sunVisibility), 0.0, 1.0)) * 0.5;
		  visibility *= pow(VoU, 2.0 * waterFactor);
		  visibility = mix(visibility, 0.5, indoorFactor) * waterFactor;
		  visibility *= clamp(length(viewPos * 0.025), 0.0, 1.0);
	#else
	float visibility = exp(pow4(VoL)) * 0.075;
	#endif

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	#ifdef OVERWORLD
	vec3 newSkyColor = pow(normalize(skyColor + 0.0001), vec3(0.75));
	vec3 vlColor = mix(pow(lightCol, vec3(0.85)), lightCol * newSkyColor, timeBrightness);
	#else
	vec3 vlColor = endLightColSqrt;
	#endif

	vec3 shadowCol = vec3(0.0);

	for (int i = 0; i < sampleCount; i++) {
		float currentDist = (pow(distanceFactor, float(i + dither) / float(sampleCount)) / distanceFactor - 1.0 / distanceFactor) / (1.0 - 1.0 / distanceFactor);

		rayShadowPos = startPos.xyz + currentDist * sampleStepS;
		rayWorldPos = gbufferModelViewInverse[3].xyz + cameraPosition + currentDist * sampleStepW;

		vec3 shadowPosT = distortShadow(rayShadowPos);
		float shadow0 = 0.0;
		float shadow1 = 0.0;

		if (length(shadowPosT.xy * 2.0 - 1.0) < 1.0) {
			shadow0 = texture2DShadow(shadowtex0, shadowPosT);

			#ifdef SHADOW_COLOR
			if (shadow0 < 1.0) {
				shadow1 = texture2DShadow(shadowtex1, shadowPosT);
				if (shadow1 > 0.0) {
					shadowCol = texture2D(shadowcolor0, shadowPosT.xy).rgb;
				}
			}
			#endif
		}

		vec3 shadow = clamp(shadow1 * pow2(shadowCol) + shadow0 * vlColor * float(isEyeInWater == 0), 0.0, 8.0);

		//Crepuscular rays
		#ifdef VC_SHADOWS
		if (rayWorldPos.y < VC_HEIGHT + VC_THICKNESS + 25.0) {
			float speed = VC_SPEED;
			float amount = VC_AMOUNT;
			float frequency = VC_FREQUENCY;
			float thickness = VC_THICKNESS;
			float density = VC_DENSITY;
			float detail = VC_DETAIL;
			float height = VC_HEIGHT;

			getDynamicWeather(speed, amount, frequency, thickness, density, detail, height);

			vec2 wind = vec2(frameTimeCounter * speed * 0.005, sin(frameTimeCounter * speed * 0.1) * 0.01) * speed * 0.1;
			vec3 cloudShadowPos = rayWorldPos + (worldSunVec / max(abs(worldSunVec.y), 0.0)) * max((VC_HEIGHT + VC_THICKNESS + 25.0) - rayWorldPos.y, 0.0);

			float noise = 0.0;
			getCloudSample(cloudShadowPos.xz, wind, amount, frequency, thickness, density, detail, noise);
			shadow *= noise;
		}
		#endif

		finalVL += shadow;
	}
	finalVL /= sampleCount;
    finalVL *= visibility;

	if (isEyeInWater == 1.0) finalVL *= mix(waterColorSqrt, waterColorSqrt * weatherCol, wetness) * (4.0 + sunVisibility * 8.0);

    vl += pow(finalVL, vec3(1.0 - pow(length(finalVL), 1.25) * 0.25));
}