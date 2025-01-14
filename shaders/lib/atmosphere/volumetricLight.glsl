float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

#ifdef VC_SHADOWS
void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float density, inout float height) {
	float dayAmountFactor = abs(worldDay % 7 / 2 - 0.5) * 0.5;
	float dayDensityFactor = abs(worldDay % 9 / 4 - worldDay % 2);
	float dayFrequencyFactor = 1.0 + abs(worldDay % 6 / 4 - worldDay % 2) * 0.65;

	speed += wetness;
	amount = mix(amount, 11.5, wetness) - dayAmountFactor;
	density += dayDensityFactor;
	frequency *= dayFrequencyFactor;
}

void getCloudShadow(vec2 rayPos, vec2 wind, float amount, float frequency, float density, inout float noise) {
	rayPos *= 0.000125 * frequency;

	float noiseBase = texture2D(noisetex, rayPos + 0.5 + wind * 0.5).g;
		  noiseBase = pow2(1.0 - noiseBase) * 0.5 + 0.4 - wetness * 0.025;
	
	noise = noiseBase * 22.0;
	noise = max(noise - amount, 0.0) * (density * 0.25);
	noise /= sqrt(noise * noise + 0.25);
	noise = clamp(noise, 0.0, 1.0);
	noise = exp(noise * -10.0);
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
	float lViewPos = length(viewPos);
	vec3 nViewPos = normalize(viewPos);
	vec3 worldPos = ToWorld(viewPos);
	vec3 shadowPos = mat3(shadowModelView) * worldPos + shadowModelView[3].xyz;
		 shadowPos = diagonal3(shadowProjection) * shadowPos + shadowProjection[3].xyz;
	vec3 startPos = ToShadowProjected(vec3(0.0));
	vec3 sampleStepS = shadowPos - startPos;
	vec3 sampleStepW = worldPos - gbufferModelViewInverse[3].xyz;

	float minDistFactor = 2.0;
	float maxDistFactor = 384.0;
	#ifdef DISTANT_HORIZONS
		  maxDistFactor += dhRenderDistance;
	#endif

	float maxDist = min(length(sampleStepW), maxDistFactor) / length(sampleStepW);
	
	sampleStepS *= maxDist;
	sampleStepW *= maxDist;

	vec3 rayShadowPos = startPos;
	vec3 rayWorldPos = vec3(0.0);

    //Total Visibility & Variables
    float indoorFactor = (1.0 - eBS * eBS) * float(isEyeInWater == 0 && cameraPosition.y < 1000.0);
	#if MC_VERSION >= 12104
		  indoorFactor = mix(indoorFactor, 1.0, isPaleGarden * 0.5);
	#endif

	float VoL = dot(nViewPos, lightVec);
	float VoLC = clamp(VoL, 0.0, 1.0);
		  VoLC = mix(VoLC, 0.5, 0.25 * float(isEyeInWater == 1));
	float VoLP = 2.0 + VoL;

	#ifdef OVERWORLD
	float waterFactor = 1.0 - float(isEyeInWater == 1) * 0.5;
	float denseForestFactor = min(isSwamp + isJungle, 1.0);
	float meVisRatio = (1.0 - VL_STRENGTH_RATIO) + clamp(exp(VoLC * VoLC * 0.25) * pow(VoLC, 1.3), 0.0, 1.0) * VL_STRENGTH_RATIO;
	float visibility = float(z0 > 0.56) * shadowFade * VoLP * VL_STRENGTH;
		  visibility *= mix(meVisRatio, 1.0, timeBrightness);
		  visibility = mix(visibility, 0.5, indoorFactor) * waterFactor;
		  visibility *= clamp(1.0 - exp(-lViewPos * 0.0075), 0.0, 1.0);
	#else
	float visibility = exp(pow4(VoLC)) * 0.075;
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

	#ifdef VC_SHADOWS
	//Cloud Parameters
    float speed = VC_SPEED;
    float amount = VC_AMOUNT;
    float frequency = VC_FREQUENCY;
    float density = VC_DENSITY;
    float height = VC_HEIGHT;

    getDynamicWeather(speed, amount, frequency, density, height);

	vec2 wind = vec2(frameTimeCounter * speed * 0.005, sin(frameTimeCounter * speed * 0.1) * 0.01) * speed * 0.1;
	#endif

	for (int i = 0; i < sampleCount; i++) {
		float currentDist = (pow(minDistFactor, float(i + dither) / float(sampleCount)) / minDistFactor - 1.0 / minDistFactor) / (1.0 - 1.0 / minDistFactor);

		rayWorldPos = gbufferModelViewInverse[3].xyz + cameraPosition + currentDist * sampleStepW;
		rayShadowPos = startPos.xyz + currentDist * sampleStepS;
		rayShadowPos = distortShadow(rayShadowPos);

		float shadow0 = 0.0;
		float shadow1 = 0.0;

		if (length(rayShadowPos.xy * 2.0 - 1.0) < 1.0) {
			shadow0 = texture2DShadow(shadowtex0, rayShadowPos);

			#ifdef SHADOW_COLOR
			if (shadow0 < 1.0) {
				shadow1 = texture2DShadow(shadowtex1, rayShadowPos);
				if (shadow1 > 0.0) {
					shadowCol = texture2D(shadowcolor0, rayShadowPos.xy).rgb;
				}
			}
			#endif
		}

		vec3 shadow = clamp(shadow1 * pow2(shadowCol) + shadow0 * vlColor * float(isEyeInWater == 0), 0.0, 8.0);

		//Crepuscular rays
		#ifdef VC_SHADOWS
		if (rayWorldPos.y < VC_HEIGHT + VC_THICKNESS + 25.0) {
			vec3 cloudShadowPos = rayWorldPos + (worldSunVec / max(abs(worldSunVec.y), 0.0)) * max((VC_HEIGHT + VC_THICKNESS + 25.0) - rayWorldPos.y, 0.0);

			float noise = 0.0;
			getCloudShadow(cloudShadowPos.xz, wind, amount, frequency, density, noise);
			shadow *= noise;
		}
		shadow *= (1.0 - min((rayWorldPos.y - VC_THICKNESS) * (1.0 / (VC_HEIGHT + VC_THICKNESS + 25.0)), 1.0));
		#endif

		finalVL += shadow;
	}
    finalVL *= visibility;
	finalVL /= sampleCount;

	if (isEyeInWater == 1.0) finalVL *= mix(waterColorSqrt, waterColorSqrt * weatherCol, wetness) * (4.0 + sunVisibility * 8.0);

    vl += pow(finalVL, vec3(1.0 - pow(length(finalVL), 1.25) * 0.25));
}