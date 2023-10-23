//FXAA 3.11 from http://blog.simonrodriguez.fr/articles/30-07-2016_implementing_fxaa.html
const float quality[12] = float[12] (1.0, 1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0);

float getLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

vec3 FXAA311(vec3 color) {
	const float edgeThresholdMin = 0.0625;
	const float edgeThresholdMax = 0.7500;
	const float subpixelQuality = 0.75;
	
	vec2 pixelSize = 1.0 / vec2(viewWidth, viewHeight);
	
	float lumaCenter = getLuminance(color);
	float lumaDown   = getLuminance(texture2DLod(colortex1, texCoord + vec2( 0.0, -1.0) * pixelSize, 0).rgb);
	float lumaUp     = getLuminance(texture2DLod(colortex1, texCoord + vec2( 0.0,  1.0) * pixelSize, 0).rgb);
	float lumaLeft   = getLuminance(texture2DLod(colortex1, texCoord + vec2(-1.0,  0.0) * pixelSize, 0).rgb);
	float lumaRight  = getLuminance(texture2DLod(colortex1, texCoord + vec2( 1.0,  0.0) * pixelSize, 0).rgb);
	
	float lumaMin = min(lumaCenter, min(min(lumaDown, lumaUp), min(lumaLeft, lumaRight)));
	float lumaMax = max(lumaCenter, max(max(lumaDown, lumaUp), max(lumaLeft, lumaRight)));
	
	float lumaRange = lumaMax - lumaMin;
	
	if (lumaRange > max(edgeThresholdMin, lumaMax * edgeThresholdMax)) {
		float lumaDownLeft  = getLuminance(texture2DLod(colortex1, texCoord + vec2(-1.0, -1.0) * pixelSize, 0).rgb);
		float lumaUpRight   = getLuminance(texture2DLod(colortex1, texCoord + vec2( 1.0,  1.0) * pixelSize, 0).rgb);
		float lumaUpLeft    = getLuminance(texture2DLod(colortex1, texCoord + vec2(-1.0,  1.0) * pixelSize, 0).rgb);
		float lumaDownRight = getLuminance(texture2DLod(colortex1, texCoord + vec2( 1.0, -1.0) * pixelSize, 0).rgb);
		
		float lumaDownUp    = lumaDown + lumaUp;
		float lumaLeftRight = lumaLeft + lumaRight;
		
		float lumaLeftCorners  = lumaDownLeft  + lumaUpLeft;
		float lumaDownCorners  = lumaDownLeft  + lumaDownRight;
		float lumaRightCorners = lumaDownRight + lumaUpRight;
		float lumaUpCorners    = lumaUpRight   + lumaUpLeft;
		
		float edgeHorizontal = abs(-2.0 * lumaLeft   + lumaLeftCorners ) +
							   abs(-2.0 * lumaCenter + lumaDownUp      ) * 2.0 +
							   abs(-2.0 * lumaRight  + lumaRightCorners);
		float edgeVertical   = abs(-2.0 * lumaUp     + lumaUpCorners   ) +
							   abs(-2.0 * lumaCenter + lumaLeftRight   ) * 2.0 +
							   abs(-2.0 * lumaDown   + lumaDownCorners );
		
		bool isHorizontal = edgeHorizontal >= edgeVertical;		
		
		float luma1 = isHorizontal ? lumaDown : lumaLeft;
		float luma2 = isHorizontal ? lumaUp : lumaRight;
		float gradient1 = luma1 - lumaCenter;
		float gradient2 = luma2 - lumaCenter;
		
		bool is1Steepest = abs(gradient1) >= abs(gradient2);
		float gradientScaled = 0.25 * max(abs(gradient1), abs(gradient2));
		
		float stepLength = isHorizontal ? pixelSize.y : pixelSize.x;

		float lumaLocalAverage = 0.0;

		if (is1Steepest) {
			stepLength -= stepLength;
			lumaLocalAverage = 0.5 * (luma1 + lumaCenter);
		} else {
			lumaLocalAverage = 0.5 * (luma2 + lumaCenter);
		}

		vec2 currentUv = texCoord;

		if (isHorizontal) {
			currentUv.y += stepLength * 0.5;
		} else {
			currentUv.x += stepLength * 0.5;
		}
		
		vec2 offset = isHorizontal ? vec2(pixelSize.x, 0.0) : vec2(0.0, pixelSize.y);
		
		vec2 texCoord1 = currentUv - offset;
		vec2 texCoord2 = currentUv + offset;

		float lumaEnd1 = getLuminance(texture2DLod(colortex1, texCoord1, 0).rgb);
		float lumaEnd2 = getLuminance(texture2DLod(colortex1, texCoord2, 0).rgb);
		lumaEnd1 -= lumaLocalAverage;
		lumaEnd2 -= lumaLocalAverage;
		
		bool reached1 = abs(lumaEnd1) >= gradientScaled;
		bool reached2 = abs(lumaEnd2) >= gradientScaled;
		bool reachedBoth = reached1 && reached2;
		
		if (!reached1) texCoord1 -= offset;
		if (!reached2) texCoord2 += offset;
		
		if (!reachedBoth) {
			for(int i = 2; i < 12; i++) {
				if (!reached1) {
					lumaEnd1 = getLuminance(texture2DLod(colortex1, texCoord1, 0).rgb);
					lumaEnd1 = lumaEnd1 - lumaLocalAverage;
				}
				if (!reached2) {
					lumaEnd2 = getLuminance(texture2DLod(colortex1, texCoord2, 0).rgb);
					lumaEnd2 = lumaEnd2 - lumaLocalAverage;
				}
				
				reached1 = abs(lumaEnd1) >= gradientScaled;
				reached2 = abs(lumaEnd2) >= gradientScaled;
				reachedBoth = reached1 && reached2;

				if (!reached1)
					texCoord1 -= offset * quality[i];
					
				if (!reached2)
					texCoord2 += offset * quality[i];
				
				if (reachedBoth) break;
			}
		}
		
		float distance1 = isHorizontal ? (texCoord.x - texCoord1.x) : (texCoord.y - texCoord1.y);
		float distance2 = isHorizontal ? (texCoord2.x - texCoord.x) : (texCoord2.y - texCoord.y);

		bool isDirection1 = distance1 < distance2;
		float distanceFinal = min(distance1, distance2);

		float edgeThickness = (distance1 + distance2);

		float pixelOffset = -distanceFinal / edgeThickness + 0.5;
		
		bool isLumaCenterSmaller = lumaCenter < lumaLocalAverage;

		bool correctVariation = ((isDirection1 ? lumaEnd1 : lumaEnd2) < 0.0) != isLumaCenterSmaller;

		float finalOffset = correctVariation ? pixelOffset : 0.0;
		
		float lumaAverage = (1.0 / 12.0) * (2.0 * (lumaDownUp + lumaLeftRight) + lumaLeftCorners + lumaRightCorners);
		float subPixelOffset1 = clamp(abs(lumaAverage - lumaCenter) / lumaRange, 0.0, 1.0);
		float subPixelOffset2 = (-2.0 * subPixelOffset1 + 3.0) * subPixelOffset1 * subPixelOffset1;
		float subPixelOffsetFinal = subPixelOffset2 * subPixelOffset2 * subpixelQuality;

		finalOffset = max(finalOffset, subPixelOffsetFinal);
		
		// Compute the final UV coordinates.
		vec2 finalTexCoord = texCoord;
		if (isHorizontal) {
			finalTexCoord.y += finalOffset * stepLength;
		} else {
			finalTexCoord.x += finalOffset * stepLength;
		}

		color = texture2DLod(colortex1, finalTexCoord, 0).rgb;
	}

	return color;
}
