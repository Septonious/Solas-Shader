const vec2 roughReflectionOffsets[4] = vec2[4](
   vec2(0.21848650099008202, -0.09211370200809937),
   vec2(-0.5866112654782878, 0.32153793477769893),
   vec2(-0.06595078555407359, -0.879656059066481),
   vec2(0.43407555004227927, 0.6502318262968816)
);

void getReflection(inout vec4 color, in vec3 viewPos, in vec3 normal, in float fresnel, in float smoothness, in float skyLightMap) {
	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif

	#ifndef OVERWORLD
	int sampleCount = 30;
	#else
	int sampleCount = int(30 - skyLightMap * 15);
	#endif

	sampleCount = int(sampleCount * (0.5 + smoothness * 0.5)); //No need for high precision when the reflection is gonna be blurred anyway

    float border = 0.0;
    float lRfragPos = 0.0;
    float dist = 0.0;
    vec2 cdist = vec2(0.0);
	vec3 reflectPos = Raytrace(depthtex1, viewPos, normal, blueNoiseDither, fresnel, 6, 0.5, 0.1, 1.5, sampleCount, border, lRfragPos, dist, cdist);
	vec4 reflection = vec4(0.0);

    if (reflectPos.z < 0.99997) {
        if (border > 0.001) {
            vec2 edgeFactor = pow4(cdist);
            reflectPos.y += blueNoiseDither * (edgeFactor.x + edgeFactor.y) * 0.05;

            float lodFactor = 1.0 - exp(-0.125 * pow2(1.0 - smoothness) * dist);
            float lod = log2(viewHeight * 0.125 * pow2(1.0 - smoothness) * lodFactor) * (0.8 - smoothness * 0.4);
            lod = max(lod - 1.0, 0.0);

            for (int i = -2; i <= 2; i++) {
                for (int j = -2; j <= 2; j++) {
                    vec2 offset = vec2(i, j) * (0.1 + exp2(lod - 1.0)) / vec2(viewWidth, viewHeight);
                    reflection += texture2DLod(colortex0, reflectPos.xy + offset, max(lod - 1, 0.0));
                }
            }

            reflection /= 25.0;

            edgeFactor.x *= edgeFactor.x;
            edgeFactor = 1.0 - edgeFactor;
            reflection.a *= border * pow(edgeFactor.x * edgeFactor.y, (1.0 + length(reflection.rgb)) * 2.0);
        }

        reflection.a *= clamp(lRfragPos - length(viewPos) + 2.5, 0.0, 1.0);
    }

	vec3 falloff = vec3(0.0);

	if (reflection.a < 1.0 && isEyeInWater == 0) {
		if (skyLightMap > 0.95) {
			#ifdef OVERWORLD
			vec3 viewPosRef = reflect(normalize(viewPos), normal);
			vec3 worldPosRef = reflect(normalize(ToWorld(viewPos)), normal);
			vec3 reflectedAtmosphere = getAtmosphere(viewPosRef.xyz, worldPosRef.xyz);
			reflectedAtmosphere = pow(reflectedAtmosphere, vec3(2.2));
			falloff = mix(falloff, reflectedAtmosphere, skyLightMap);
			#endif
		}

		#if MC_VERSION >= 11900
		falloff *= 1.0 - darknessFactor;
		#endif

		falloff *= 1.0 - blindFactor;
	}

	vec3 finalReflection = max(mix(falloff, reflection.rgb, reflection.a), vec3(0.0));

	#ifdef GENERATED_SPECULAR
	smoothness = pow(smoothness, max(1.0, 1.5 - smoothness)); //Prevents crazy strong reflections on rough surfaces
	#endif

	color.rgb += finalReflection * fresnel * smoothness;
}