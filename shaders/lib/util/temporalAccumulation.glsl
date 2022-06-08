vec4 getTemporalAccumulation(inout vec3 color, float tempData, sampler2D temptex) {
	vec3 coord = vec3(texCoord, texture2D(depthtex1, texCoord).r);
	vec2 prvCoord = Reprojection(coord);
	
	vec3 tempColor = texture2D(temptex, prvCoord).gba;
	vec2 viewResolution = vec2(viewWidth, viewHeight);
	
	float blendFactor = float(
		prvCoord.x > 0.0 && prvCoord.x < 1.0 &&
		prvCoord.y > 0.0 && prvCoord.y < 1.0
	);
	
	blendFactor *= 0.9 + 0.05;
	
	color = mix(color, tempColor, blendFactor);

	return vec4(tempData, color);
}