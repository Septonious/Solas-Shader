vec2 neighbourOffsets[8] = vec2[8](
	vec2( 0.0, -1.0),
	vec2(-1.0,  0.0),
	vec2( 1.0,  0.0),
	vec2( 0.0,  1.0),
	vec2(-1.0, -1.0),
	vec2( 1.0, -1.0),
	vec2(-1.0,  1.0),
	vec2( 1.0,  1.0)
);

//Catmull-Rom sampling from Filmic SMAA presentation
vec3 textureCatmullRom(sampler2D colortex, vec2 coord, vec2 view) {
    vec2 position = coord * view;
    vec2 centerPosition = floor(position - 0.5) + 0.5;
    vec2 diff = position - centerPosition;
    vec2 diff2 = diff * diff;
    vec2 diff3 = diff * diff2;

    const float c = 0.7;
    vec2 w0 = -c * diff3 + 2.0 * c * diff2 - c * diff;
    vec2 w1 =  (2.0 - c) * diff3 - (3.0 - c) * diff2 + 1.0;
    vec2 w2 = -(2.0 - c) * diff3 + (3.0 - 2.0 * c) * diff2 + c * diff;
    vec2 w3 = c * diff3 - c * diff2;

    vec2 w12 = w1 + w2;
    vec2 tc12 = (centerPosition + w2 / w12) / view;

    vec2 tc0 = (centerPosition - 1.0) / view;
    vec2 tc3 = (centerPosition + 2.0) / view;
    vec4 color = vec4(texture2DLod(colortex, vec2(tc12.x, tc0.y ), 0).gba, 1.0) * (w12.x * w0.y ) +
                 vec4(texture2DLod(colortex, vec2(tc0.x,  tc12.y), 0).gba, 1.0) * (w0.x  * w12.y) +
                 vec4(texture2DLod(colortex, vec2(tc12.x, tc12.y), 0).gba, 1.0) * (w12.x * w12.y) +
                 vec4(texture2DLod(colortex, vec2(tc3.x,  tc12.y), 0).gba, 1.0) * (w3.x  * w12.y) +
                 vec4(texture2DLod(colortex, vec2(tc12.x, tc3.y ), 0).gba, 1.0) * (w12.x * w3.y );

    return color.rgb / color.a;
}

vec3 RGBToYCoCg(vec3 color) {
	return vec3(
		color.r * 0.25 + color.g * 0.5 + color.b * 0.25,
		color.r * 0.5 - color.b * 0.5,
		color.r * -0.25 + color.g * 0.5 + color.b * -0.25
	);
}

vec3 YCoCgToRGB(vec3 color) {
	float n = color.r - color.b;
	return vec3(n + color.g, color.r + color.b, n - color.g);
}

vec3 ClipAABB(vec3 q, vec3 minAABB, vec3 maxAABB){
	vec3 clipP = (maxAABB + minAABB) * 0.5;
	vec3 clipE = (maxAABB - minAABB) * 0.5 + 0.00000001;

	vec3 clipV = q - vec3(clipP);
	vec3 unitV = clipV.xyz / clipE;
	vec3 unitA = abs(unitV);
	float maxUnit = max(unitA.x, max(unitA.y, unitA.z));

	if (maxUnit > 1.0) return vec3(clipP) + clipV / maxUnit;
	else return q;
}

vec3 NeighbourhoodClipping(vec3 color, vec3 tempColor, vec2 view) {
	vec3 minclr = RGBToYCoCg(color);
	vec3 maxclr = minclr;

	for(int i = 0; i < 8; i++) {
		vec2 offset = neighbourOffsets[i] * view;
		vec3 clr = texture2DLod(colortex1, texCoord + offset, 0.0).rgb;

		clr = RGBToYCoCg(clr);
		minclr = min(minclr, clr); maxclr = max(maxclr, clr);
	}

	tempColor = RGBToYCoCg(tempColor);
	tempColor = ClipAABB(tempColor, minclr, maxclr);

	return YCoCgToRGB(tempColor);
}

vec4 TemporalAA(inout vec3 color, float tempData, float z1) {
	vec2 view = vec2(viewWidth, viewHeight);
	vec3 coord = vec3(texCoord, z1);
	vec2 prvCoord = Reprojection(coord);
	
	vec3 tempColor = textureCatmullRom(colortex2, prvCoord, view);

	if (tempColor == vec3(0.0)) {
		color = texture2DLod(colortex1, texCoord, 0).rgb;
		return vec4(tempData, color);
	}

	tempColor = NeighbourhoodClipping(color, tempColor, 1.0 / view);

	vec2 velocity = (texCoord - prvCoord.xy) * view;
	float blendFactor = float(
		prvCoord.x > 0.0 && prvCoord.x < 1.0 &&
		prvCoord.y > 0.0 && prvCoord.y < 1.0
	);
	blendFactor *= exp(-length(velocity)) * 0.3 + 0.55;
	
	color = mix(color, tempColor, blendFactor);

	return vec4(tempData, color);
}