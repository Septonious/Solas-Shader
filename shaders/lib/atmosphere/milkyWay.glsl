void drawMilkyWay(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor, inout float nebulaFactor, in float volumetricClouds) {
	float visibility = pow4(moonVisibility) * (1.0 - rainStrength) * (1.0 - volumetricClouds) * sqrt(max(VoU, 0.0)) * MILKY_WAY_BRIGHTNESS * caveFactor;

	if (0 < visibility) {
		vec2 planeCoord = worldPos.zx / (worldPos.y + length(worldPos.zyx));
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
             milkyWay.rgb = (lightNight * 0.75 + vec3(0.25)) * milkyWay.rgb * pow6(milkyWay.a) * length(milkyWay.rgb) * visibility;
		nebulaFactor = length(milkyWay.rgb) * 8.0;
        #ifdef GBUFFERS_WATER
             milkyWay.rgb *= 3.0; //brightness compensation for water reflections
        #endif
		color += milkyWay.rgb;
	}
}