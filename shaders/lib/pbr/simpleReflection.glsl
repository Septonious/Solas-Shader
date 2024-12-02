const vec2 refOffsets[4] = vec2[4](
	vec2( 1.5,  0.5),
	vec2(-0.5,  1.5),
	vec2(-1.5, -0.5),
	vec2( 0.5, -1.5)
);

void getReflection(inout vec4 color, in vec3 viewPos, in vec3 normal, in float fresnel, in float smoothness) {
	float border = 0.0;
	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif

	vec3 falloff = vec3(0.0);
	vec4 reflectPos = rayTrace(depthtex0, viewPos, normal, blueNoiseDither, border, 6, 20, 0.1, 1.4);

	border = clamp(13.333 * (1.0 - border), 0.0, 1.0);

	#ifdef OVERWORLD
	vec3 skyRefPos = reflect(normalize(viewPos), normal);
	vec3 sunPos = vec3(gbufferModelViewInverse * vec4(sunVec * 128.0, 1.0));
	vec3 sunCoord = sunPos / (sunPos.y + length(sunPos.xz));
	falloff = getAtmosphericScattering(skyRefPos, normalize(sunCoord)) * eBS;
	falloff *= falloff;

	#if MC_VERSION >= 11900
	falloff *= 1.0 - darknessFactor;
	#endif

	falloff *= 1.0 - blindFactor;
	#endif

	float fovScale = gbufferProjection[1][1] / 1.37;
	float dist = 0.25 * reflectPos.a * fovScale;
	float lod = log2(viewHeight * dist) * sqrt(1.0 - smoothness) * 2.0;

	vec4 reflection = texture2D(colortex0, reflectPos.xy + lod * refOffsets[0] / vec2(viewWidth, viewHeight));
		 reflection+= texture2D(colortex0, reflectPos.xy + lod * refOffsets[1] / vec2(viewWidth, viewHeight));
		 reflection+= texture2D(colortex0, reflectPos.xy + lod * refOffsets[2] / vec2(viewWidth, viewHeight));
		 reflection+= texture2D(colortex0, reflectPos.xy + lod * refOffsets[3] / vec2(viewWidth, viewHeight));
	reflection *= 0.25;
	reflection.a *= border;

	color.rgb = mix(color.rgb, mix(falloff, reflection.rgb, reflection.a), fresnel * smoothness);
}