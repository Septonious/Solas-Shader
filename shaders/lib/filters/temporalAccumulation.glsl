vec4 getTemporalAccumulation(inout vec3 color, sampler2D temptex, float tempData, float z0) {
	vec3 coord = vec3(texCoord, z0);
	vec2 prvCoord = Reprojection(coord);
	
	vec3 tempColor = texture2D(temptex, prvCoord).gba;
	vec2 viewResolution = vec2(viewWidth, viewHeight);
	
	float blendFactor = float(
		prvCoord.x > 0.0 && prvCoord.x < 1.0 &&
		prvCoord.y > 0.0 && prvCoord.y < 1.0
	);
	
	color = mix(color, tempColor, blendFactor * 0.8);

	return vec4(tempData, color);
}