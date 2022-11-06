const vec2 neighbourhoodOffsets[8] = vec2[8](
	vec2( 0.0, -1.0),
	vec2(-1.0,  0.0),
	vec2( 1.0,  0.0),
	vec2( 0.0,  1.0),
	vec2(-1.0, -1.0),
	vec2( 1.0, -1.0),
	vec2(-1.0,  1.0),
	vec2( 1.0,  1.0)
);

vec3 RGBToYCoCg(vec3 col) {
	return vec3(
		col.r * 0.25 + col.g * 0.5 + col.b * 0.25,
		col.r * 0.5 - col.b * 0.5,
		col.r * -0.25 + col.g * 0.5 + col.b * -0.25
	);
}

vec3 YCoCgToRGB(vec3 col) {
	float n = col.r - col.b;

	return vec3(n + col.g, col.r + col.b, n - col.g);
}

vec3 ClipAABB(vec3 q,vec3 aabb_min, vec3 aabb_max){
	vec3 p_clip = 0.5 * (aabb_max + aabb_min);
	vec3 e_clip = 0.5 * (aabb_max - aabb_min) + 0.00000001;

	vec3 v_clip = q - vec3(p_clip);
	vec3 v_unit = v_clip.xyz / e_clip;
	vec3 a_unit = abs(v_unit);
	float ma_unit = max(a_unit.x, max(a_unit.y, a_unit.z));

	if (ma_unit > 1.0)
		return vec3(p_clip) + v_clip / ma_unit;
	else
		return q;
}

vec3 NeighbourhoodClamping(vec3 color, vec3 tempColor, vec2 viewScale, sampler2D colortex) {
	vec3 minclr = RGBToYCoCg(color);
	vec3 maxclr = minclr;

	for (int i = 0; i < 8; i++) {
		vec2 offset = neighbourhoodOffsets[i] * viewScale;
		vec3 clr = texture2D(colortex, texCoord + offset).rgb;

		clr = RGBToYCoCg(clr);
		minclr = min(minclr, clr);
		maxclr = max(maxclr, clr);
	}

	tempColor = RGBToYCoCg(tempColor);
	tempColor = ClipAABB(tempColor, minclr, maxclr);

	return YCoCgToRGB(tempColor);
}

vec4 TemporalAA(inout vec3 color, float tempData, sampler2D colortex, sampler2D temptex) {
	float z1 = texture2D(depthtex1, texCoord).r;
	vec3 coord = vec3(texCoord, z1);
	vec2 prvCoord = Reprojection(coord);
	
	vec3 tempColor = texture2D(temptex, prvCoord).gba;
	vec2 viewResolution = vec2(viewWidth, viewHeight);

	if (tempColor == vec3(0.0)) return vec4(tempData, color);
	
	tempColor = NeighbourhoodClamping(color, tempColor, 1.0 / viewResolution, colortex);
	
	float blendFactor = float(
		prvCoord.x > 0.0 && prvCoord.x < 1.0 &&
		prvCoord.y > 0.0 && prvCoord.y < 1.0
	);
	
	vec2 velocity = (texCoord - prvCoord.xy) * viewResolution;

	blendFactor *= exp(-length(velocity)) * 0.2 + 0.7;
	
	color = mix(color, tempColor, blendFactor);

	return vec4(tempData, color);
}