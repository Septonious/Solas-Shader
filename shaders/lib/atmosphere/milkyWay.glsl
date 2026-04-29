void drawMilkyWay(inout vec3 color, in vec3 worldPos, in float VoU, in float VoM, in float caveFactor, inout float nebulaFactor, in float auroraOcclusion) {
    float altitudeFactor = min(max(cameraPosition.y, 0.0) / KARMAN_LINE, 1.0);
    float VoUFactor = mix(sqrt(max(VoU, 0.0)), VoU * 0.5 + 0.5, altitudeFactor);
	float visibility = mix(pow4(moonVisibility) * (1.0 - rainStrength), 1.0, altitudeFactor) * VoUFactor * MILKY_WAY_BRIGHTNESS * caveFactor;

	if (visibility > 0.1) {
        #ifdef GENERATED_NIGHT_NEBULA
        vec3 nWorldPos = normalize(worldPos);
        float VoMClamped = clamp(VoM, 0.0, 1.0);
    	vec2 nebulaPlaneCoord = worldPos.xz / (length(worldPos.y) + length(vec3(worldPos.x, worldPos.y, worldPos.z)));
                nebulaPlaneCoord += frameTimeCounter * 0.001;
                nebulaPlaneCoord += cameraPosition.xz * 0.00001;
        float nebulaHeightFactor = max(1.0 - sqrt(nWorldPos.y), 0.0);
        float baseOctave = texture2D(noisetex, nebulaPlaneCoord * 0.125).g;
                baseOctave = max(baseOctave - 0.2, 0.0);
        float midOctave = texture2D(noisetex, nebulaPlaneCoord * 0.25).r;
                midOctave = max(midOctave - 0.175, nebulaHeightFactor * 0.25);
        float detailOctave = texture2D(noisetex, nebulaPlaneCoord).r;
                detailOctave = max(detailOctave - 0.075, nebulaHeightFactor * 0.25);
        float nebulaNoise = (0.25 + 0.75 * baseOctave) * midOctave * (0.25 + 0.75 * detailOctave) * 6.0;
        vec3 nebulaColor = vec3(0.3, 0.5 + midOctave * midOctave * midOctave * 3.0, 1.0);
                nebulaNoise = max(nebulaNoise * nWorldPos.y * pow(1.0 - nWorldPos.y, 1.5 - VoMClamped * 0.5), 0.0);
        vec3 nebula = (0.5 + VoMClamped * 0.5) * (1.0 - nebulaHeightFactor) * nebulaColor * (nebulaNoise + pow3(nebulaNoise) * 9.0) * moonVisibility * (1.0 - wetness);
        color.rgb += GENERATED_NIGHT_NEBULA_BRIGHTNESS * nebula * (1.0 - auroraOcclusion);
        nebulaFactor += length(nebula);
        #endif

		vec2 planeCoord = worldPos.zx / (length(worldPos.y) + length(worldPos.zyx));
			 planeCoord += frameTimeCounter * 0.0001;
			 planeCoord *= 0.75;
			 planeCoord.x *= 2.0;
			 planeCoord.x -= 0.2;
			 planeCoord.y -= 0.7;
		
		#ifdef DEFERRED
		vec4 milkyWay = texture2D(depthtex2, planeCoord * 0.5 + 0.6);
		#else
		vec4 milkyWay = texture2D(gaux4, planeCoord * 0.5 + 0.6);
		#endif
             milkyWay.rgb = (lightNight * 1.75 + vec3(0.25)) * milkyWay.rgb * pow(milkyWay.a, 6.0 - altitudeFactor * 3.0) * length(milkyWay.rgb) * visibility;
		nebulaFactor = length(milkyWay.rgb) * (5.0 - altitudeFactor * 3.0);
        #ifdef GBUFFERS_WATER
             milkyWay.rgb *= 3.0; //brightness compensation for water reflections
        #endif
		color += milkyWay.rgb * (1.0 - auroraOcclusion);
	}
}