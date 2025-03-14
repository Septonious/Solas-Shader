vec2 aoSampleOffsets[4] = vec2[4](
	vec2( 1.5,  0.5),
	vec2(-0.5,  1.5),
	vec2(-1.5, -0.5),
	vec2( 0.5, -1.5)
);

vec2 aoDepthOffsets[4] = vec2[4](
	vec2( 2.0,  1.0),
	vec2(-1.0,  2.0),
	vec2(-2.0, -1.0),
	vec2( 1.0, -2.0)
);

float getLinearDepth(in float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

float getAmbientOcclusion(float z){
	float ao = 0.0;
	float tw = 0.0;
	float lz = getLinearDepth(z);
	
	for(int i = 0; i < 4; i++){
		vec2 sampleOffset = aoSampleOffsets[i] / vec2(viewWidth, viewHeight);
		vec2 depthOffset = aoDepthOffsets[i] / vec2(viewWidth, viewHeight);
		float samplez = getLinearDepth(texture2D(depthtex0, texCoord + depthOffset).r);
		float wg = max(1.0 - 2.0 * far * abs(lz - samplez), 0.00001);
		ao += texture2D(colortex1, texCoord + sampleOffset).b * wg;
		tw += wg;
	}
	ao /= tw;
	if(tw < 0.0001) ao = texture2D(colortex1, texCoord).b;
	
	return pow(ao, AO_STRENGTH);
}

#ifdef DISTANT_HORIZONS
float GetDHLinearDepth(float depth) {
   return (2.0 * dhNearPlane) / (dhFarPlane + dhNearPlane - depth * (dhFarPlane - dhNearPlane));
}

float getAmbientOcclusionDH(float dhZ){
	float ao = 0.0;
	float tw = 0.0;
	float lz = GetDHLinearDepth(dhZ);
	
	for(int i = 0; i < 4; i++){
		vec2 sampleOffset = aoSampleOffsets[i] / vec2(viewWidth, viewHeight);
		vec2 depthOffset = aoDepthOffsets[i] / vec2(viewWidth, viewHeight);
		float samplez = GetDHLinearDepth(texture2D(dhDepthTex0, texCoord + depthOffset).r);
		float wg = max(1.0 - 2.0 * far * abs(lz - samplez), 0.00001);
		ao += texture2D(colortex1, texCoord + sampleOffset).b * wg;
		tw += wg;
	}
	ao /= tw;
	if(tw < 0.0001) ao = texture2D(colortex1, texCoord).b;
	
	return pow(ao, AO_STRENGTH + 1.0);
}
#endif