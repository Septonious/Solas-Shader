void getEndNebula(inout vec3 color, inout vec3 color2, in vec3 worldPos, in float VoU, inout float nebulaFactor, in float caveFactor) {
	float visibility = pow(1.0 - abs(VoU), 1.5) * END_NEBULA_BRIGHTNESS;

	if (0 < visibility) {
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