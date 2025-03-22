vec3 getMotionBlur(vec3 color, float z) {
	if (z >= 0.56) {
		float weight = 0.0;

		float dither = Bayer8(gl_FragCoord.xy);

		#ifdef TAA
		dither = fract(dither * frameTimeCounter * 16.0);
		#endif

		vec2 doublePixel = 2.0 / vec2(viewWidth, viewHeight);
		vec3 blur = vec3(0.0);
		
		vec4 currentPosition = vec4(texCoord, z, 1.0) * 2.0 - 1.0;
		
		vec4 viewPos = gbufferProjectionInverse * currentPosition;
			 viewPos = gbufferModelViewInverse * viewPos;
			 viewPos /= viewPos.w;
		
		vec3 cameraOffset = cameraPosition - previousCameraPosition;
		
		vec4 previousPos = viewPos + vec4(cameraOffset, 0.0);
			 previousPos = gbufferPreviousModelView * previousPos;
			 previousPos = gbufferPreviousProjection * previousPos;
			 previousPos /= previousPos.w;

		vec2 velocity = (currentPosition - previousPos).xy;
			 velocity = velocity / (1.0 + length(velocity)) * MOTION_BLUR_STRENGTH * 0.025;
		
		vec2 coord = texCoord - velocity * (1.5 + dither);

		for(int i = 0; i < 5; i++, coord += velocity) {
			vec2 sampleCoord = clamp(coord, doublePixel, 1.0 - doublePixel);
			float mask = float(texture2D(depthtex1, sampleCoord).r > 0.56);
			blur += texture2D(colortex0, sampleCoord).rgb * mask;
			weight += mask;
		}
		blur /= max(weight, 1.0);

		return blur;
	}
	else return color;
}