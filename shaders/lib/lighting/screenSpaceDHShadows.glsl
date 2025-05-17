vec3 ToClipDH(vec3 viewPos, bool isDH) {
	mat4 projectionMatrix = isDH ? dhProjection : gbufferProjection;
   	return projMAD(projectionMatrix, viewPos) / -viewPos.z * 0.5 + 0.5;
}

float getLinearDepth(float depth, float near, float far) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

float screenSpaceDHShadows(float z1, float dhZ1) {
    if (z1 < 0.56) return 0.0;
    bool isDH = z1 >= 1.0;

	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;
	#ifdef TAA
		  blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif

	float shadow = 1.0; 

	float near2 = near;
    float far2 = far * 4.0;

	if (isDH) {
		near2 = dhNearPlane;
		far2 = dhFarPlane;
	}
    
	vec3 viewPosDH = ToViewDH(texCoord, z1, dhZ1);
    vec3 worldPos = ToWorld(viewPosDH);
    vec3 clipPosition = ToClipDH(viewPosDH, isDH);
	vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
    vec2 viewSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);

	float rayLength = ((viewPosDH.z + sunPosition.z * far2) > -near2) ? (-near2 - viewPosDH.z) / sunPosition.z : far2;
    vec3 rayDir = ToClipDH(viewPosDH + sunPosition * rayLength, isDH) - clipPosition;
         rayDir = rayDir / max(abs(rayDir.x) / viewSize.x, abs(rayDir.y) / viewSize.y);
		 rayDir *= 4.0;

	vec3 screenPos = clipPosition + rayDir * blueNoiseDither;

	float minDepth = screenPos.z;
	float maxDepth = minDepth;

	for (int i = 0; i < 16; i++) {
		float currentDepth = texture2D(depthtex1, screenPos.xy).r;
		if (isDH) currentDepth = texture2D(dhDepthTex1, screenPos.xy).x;

		if (currentDepth < screenPos.z && currentDepth <= max(minDepth, maxDepth) && currentDepth >= min(minDepth, maxDepth)){
			vec2 linearDepth = vec2(getLinearDepth(screenPos.z, near2, far2),
								    getLinearDepth(currentDepth, near2, far2));

			if (abs(linearDepth.x - linearDepth.y) / linearDepth.x < 0.04) shadow = 0.0;
		} 
		
		minDepth = maxDepth - 1.0 / getLinearDepth(currentDepth, near2, far2);
		maxDepth += rayDir.z;
		screenPos += rayDir;
	}

	return shadow;
}