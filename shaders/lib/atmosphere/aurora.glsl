float getAuroraSample(vec2 coord, float kpIndex, float pulse, float longPulse, float auroraAltitudeMult, float auroraCameraY) {
	float t = frameTimeCounter * 0.125;

	vec2 distortedCoord = coord;

	//Soft global rotation (breaks axis lock)
	float baseAngle = (t * 0.0004) * 0.3;
	mat2 baseRot = mat2(cos(baseAngle), -sin(baseAngle),
	                     sin(baseAngle),  cos(baseAngle));

	distortedCoord = baseRot * distortedCoord;

	//Low frequency distortion. Makes aurora more chaotic and randomized
	vec2 flowUV = distortedCoord * 0.35;
	flowUV += vec2(
		sin(t * 0.0012),
		cos(t * 0.0010)
	);

	float f = texture2D(noisetex, flowUV).r * 2.0 - 1.0;

	//Perpendicular motion = curl approximation
	vec2 curlDir = normalize(vec2(
		cos(f * 6.283 + t * 0.2),
		sin(f * 6.283 + t * 0.1)
	));

	const float curlStrength = 0.125;
	vec2 warping = curlDir * f;
	distortedCoord += warping * curlStrength;

	//Now apply north-south stretch after initial distortion
	distortedCoord.y *= 0.75;
	distortedCoord.x *= 1.5;

	//Arc centered near zenith, very wide and persistent with a slight north bias
    float zenithDist = abs(coord.y + 1.0);
    float arc = exp(-3.0 * zenithDist * zenithDist);
          arc *= 0.65 + 0.35 * f;
          arc += kpIndex * kpIndex * 0.125;
          arc = fmix(arc, 1.0, auroraCameraY * auroraAltitudeMult);

	//Blurry background noise "folds"
	float sheet = texture2D(noisetex, vec2(distortedCoord.x, distortedCoord.y * 0.4 + frameTimeCounter * 0.0025)).r;
	      sheet *= sheet * sheet;

	//High frequency noise "rays"
	float rays = texture2D(noisetex, vec2(distortedCoord.x * 3.0, distortedCoord.y * 1.3) + vec2(-frameTimeCounter * 0.0015, frameTimeCounter * 0.0025)).r;

	float flashTime = sin(frameTimeCounter + distortedCoord.x * 64.0 + warping.x * 32.0);
	      flashTime = smoothstep(0.4, 1.0, flashTime);

	float aurora = sheet * ((25.0 + longPulse * 25.0) + pow8(rays) * 7500.0 + pow12(rays) * flashTime * 100000.0);

	return max(aurora * arc, 0.0);
}

float AuroraInvLerp(float v, float l, float h) {
	return clamp((v - l) / (h - l), 0.0, 1.0);
}

void computeVolumetricAurora(inout vec3 aurora, float z, float dither, in float caveFactor, in float occlusion, inout float auroraOcclusion) {
	vec3 viewPos = ToView(vec3(texCoord, z));
	vec3 nViewPos = normalize(viewPos);
	vec3 worldPos = ToWorld(viewPos);
	vec3 nWorldPos = normalize(worldPos);

	float lViewPos = length(viewPos);

	#if defined DISTANT_HORIZONS
		float dhZ = texture2D(dhDepthTex0, texCoord).r;
		vec4 dhScreenPos = vec4(texCoord, dhZ, 1.0);
		vec4 dhViewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
		dhViewPos /= dhViewPos.w;
		float lDhViewPos = length(dhViewPos.xyz);
	#elif defined VOXY
		float vxZ = texture2D(vxDepthTexOpaque, texCoord).r;
		vec4 vxScreenPos = vec4(texCoord, vxZ, 1.0);
		vec4 vxViewPos = vxProjInv * (vxScreenPos * 2.0 - 1.0);
		vxViewPos /= vxViewPos.w;
		float lVxViewPos = length(vxViewPos.xyz);
	#endif

	//The index of geomagnetic activity. Determines the brightness of Aurora, its widespreadness across the sky and tilt factor
	float kpIndex = abs(worldDay % 9 - worldDay % 4);
	      kpIndex = kpIndex - int(kpIndex == 1) + int(kpIndex > 7 && worldDay % 10 == 0);
	      kpIndex = min(max(kpIndex, 0) + isSnowy * 3, 9);
	#ifdef AURORA_ALWAYS_VISIBLE
		  kpIndex = 7;
	#endif

	//Aurora tends to get brighter and dimmer when plasma arrives or fades away
	float pulse = 0.5 + 0.5 * sin(frameTimeCounter * 0.08 + sin(frameTimeCounter * 0.013) * 0.6);
	      pulse = smoothstep(0.15, 0.85, pulse);

	float longPulse = sin(frameTimeCounter * 0.025 + sin(frameTimeCounter * 0.004) * 0.8);
	      longPulse = longPulse * (1.0 - 0.15 * abs(longPulse));

	kpIndex *= 1.0 + longPulse * 0.25;
	kpIndex /= 9.0;

    float spaceFactor = min(max(cameraPosition.y, 0.0) / KARMAN_LINE, 1.0);
    float auroraCameraY = min(cameraPosition.y, float(KARMAN_LINE));
    vec3 auroraCameraPos = vec3(cameraPosition.x, auroraCameraY, cameraPosition.z);

	//Keep the aurora volume fixed in world space like clouds, so it can be flown through.
	float auroraHeight = 100.0 - kpIndex * 25.0 * (1.0 - spaceFactor);
    float auroraAltitudeMult = 1.0 / (AURORA_ALTITUDE / auroraHeight);
	float auroraThickness = 32.0 + kpIndex * 16.0;
	float auroraBottom = auroraHeight - auroraThickness * 0.5;
	float auroraTop = auroraHeight + auroraThickness * 0.5;
	float auroraMiddle = auroraHeight;

	float verticalView = nWorldPos.y;
	if (abs(verticalView) < 0.0001) verticalView = verticalView < 0.0 ? -0.0001 : 0.0001;

	float lowerPlane = (auroraBottom - auroraCameraY * auroraAltitudeMult) / verticalView;
	float upperPlane = (auroraTop - auroraCameraY * auroraAltitudeMult) / verticalView;
	float nearestPlane = max(min(lowerPlane, upperPlane), 0.0);
	float farthestPlane = max(lowerPlane, upperPlane);

	if (farthestPlane <= 0.0) return;

	//Total visibility of aurora based on multiple factors
	float visibility = pow6(moonVisibility) * (1.0 - wetness) * (1.0 - occlusion) * caveFactor;
	      visibility *= kpIndex * (1.0 + max(longPulse * 0.5, 0.0));
	      visibility = min(visibility, 2.0) * AURORA_BRIGHTNESS;
    
	if (visibility > 0.01) {
		//Determines the quality of aurora. Since it stretches a lot during strong geomagnetic storms, we need more samples
		int samples = int(8 + kpIndex * 8);
		float sampleStep = 1.0 / samples;

		//Tilt factor. The stronger the geomagnetic storm, the less Aurora tilts towards the North
		float tiltFactor = 0.15 + kpIndex * 0.15;

		float planeDifference = farthestPlane - nearestPlane;
		float lengthScaling = abs(auroraCameraY * auroraAltitudeMult - auroraMiddle) / (auroraThickness * 0.5);
		      lengthScaling = clamp((lengthScaling - 1.0) * 0.5, 0.0, 1.0);

		float rayLength = auroraThickness * 0.5;
		      rayLength /= (4.0 * nWorldPos.y * nWorldPos.y) * lengthScaling + 1.0;

		vec3 rayIncrement = nWorldPos * rayLength;
		vec3 startPos = auroraCameraPos * auroraAltitudeMult + nearestPlane * nWorldPos;
		vec3 rayPos = startPos + rayIncrement * dither;
		float sampleTotalLength = nearestPlane + rayLength * dither;
		int sampleCount = int(min(planeDifference / rayLength, float(samples * 4)) + 4.0);

		//When aurora turns red
		float redPhase = pow3(kpIndex) * (1.0 - pulse);

		float sceneAuroraDepth = 1e20;

		if (z < 1.0) sceneAuroraDepth = lViewPos * auroraAltitudeMult;

		#if defined DISTANT_HORIZONS
			if (dhZ < 1.0) sceneAuroraDepth = min(sceneAuroraDepth, lDhViewPos * auroraAltitudeMult);
		#elif defined VOXY
			if (vxZ < 1.0) sceneAuroraDepth = min(sceneAuroraDepth, lVxViewPos * auroraAltitudeMult);
		#endif

		vec3 auroraVolume = vec3(0.0);

		for (int i = 0; i < sampleCount; i++, rayPos += rayIncrement, sampleTotalLength += rayLength) {
			float sceneDepthBias = max(0.005, sampleTotalLength * 0.001);
			if (sceneAuroraDepth + sceneDepthBias < sampleTotalLength) break;

			float heightStep = AuroraInvLerp(rayPos.y, auroraBottom, auroraTop);
			float attenuation = step(auroraBottom, rayPos.y) * step(rayPos.y, auroraTop);

			vec3 localPos = rayPos - auroraCameraPos * auroraAltitudeMult;
			vec3 planeCoord = localPos;
			     planeCoord.xz -= (rayPos.y - auroraMiddle) * vec2(tiltFactor, tiltFactor * 2.0);
			     planeCoord *= 0.05;

			vec3 auroraCoord = rayPos;
			     auroraCoord.xz -= (rayPos.y - auroraMiddle) * vec2(tiltFactor, tiltFactor * 2.0);
			     auroraCoord *= 0.05;

			vec2 coord = auroraCoord.xz;

			//We don't want the aurora to render infintely, we also want it to be closer to the north when Kp is low
			float westEast = clamp(1.0 - abs(planeCoord.x * 0.05) + kpIndex * kpIndex, 0.0, 1.0); //Fade out aurora closer to the western/eastern horizons
			float north = pow3(clamp(50.0 * kpIndex * kpIndex * kpIndex - planeCoord.z, 0.0, 1.0)); //Make aurora appear stronger in north when looking from the ground
            float poles = clamp(pow(abs(planeCoord.z * 0.1), 7.0 - kpIndex * kpIndex * 4.0), 0.0, 1.0); //Make aurora appear stronger near poles when looking from space
			float distanceFactor = clamp(1.0 - length(planeCoord.xz) * fmix(0.02, 0.08, spaceFactor), 0.0, 1.0); //Limit the max render distance
			float auroraDistribution = distanceFactor * westEast * fmix(north, poles, spaceFactor);

			if (auroraDistribution > 0.0) {
				float auroraSample = getAuroraSample(coord * 0.025, kpIndex, pulse, longPulse, auroraAltitudeMult, auroraCameraY);
				float colorMixer = pow(heightStep, 0.65 + pow3(kpIndex) * pulse * 0.1);
				float verticalFade = smoothstep(0.0, sampleStep + 0.001, heightStep) * (1.0 - smoothstep(1.0 - sampleStep - 0.001, 1.0, heightStep));

				vec3 lowColor = vec3(0.45, 1.55 - redPhase * 0.5, 0.0);
				vec3 upColor = vec3(0.95 + redPhase * 2.0, 0.10, 1.05);
				vec3 auroraColor = fmix(lowColor, upColor, colorMixer) * exp2(-4.0 * heightStep);

				auroraVolume += auroraColor * auroraSample * sqrt(auroraDistribution) * verticalFade * attenuation;
			}
		}

		auroraVolume *= visibility * sampleStep;
		aurora += auroraVolume;
		auroraOcclusion += clamp(length(auroraVolume) * 2.0, 0.0, 1.0);
	}
}
