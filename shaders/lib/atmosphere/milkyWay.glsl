void drawMilkyWay(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor, inout float nebulaFactor, in float volumetricClouds) {
	float visibility = (1.0 - timeBrightnessSqrt) * (1.0 - wetness) * (1.0 - volumetricClouds) * sqrt(max(VoU, 0.0)) * MILKY_WAY_BRIGHTNESS * caveFactor;

	if (0 < visibility) {
		vec2 planeCoord = worldPos.zx / (worldPos.y + length(worldPos.zyx));
			 planeCoord += frameTimeCounter * 0.0001;
			 planeCoord *= 0.8;
			 planeCoord.x *= 1.9;
		
		vec4 milkyWay = texture2D(depthtex2, planeCoord * 0.5 + 0.6);
             milkyWay.rgb = mix(lightNight, vec3(1.0), 0.25) * milkyWay.rgb * pow6(milkyWay.a) * length(milkyWay.rgb) * visibility;
		nebulaFactor = length(milkyWay.rgb);
        #ifdef GBUFFERS_WATER
             milkyWay.rgb *= 3.0; //brightness compensation for water reflections
        #endif
		color += milkyWay.rgb;
	}
}