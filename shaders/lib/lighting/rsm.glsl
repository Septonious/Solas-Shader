vec2 spiralOffset(float x, float total) {
	float n = x * 2.39996322;
	return vec2(sin(n), cos(n)) * (x / total);
}

vec3 computeRSM(vec3 worldNormal, vec3 worldPos, vec3 viewPos, float z0) {
    vec3 gi = vec3(0.0);

    float giDistance = 1.0 - clamp(length(viewPos.xz) / shadowDistance, 0.0, 1.0);

    if (giDistance > 0.0 && (z0 > 0.56 && z0 != 1.0)) {
        float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

        #ifdef TAA
        blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
        #endif

        vec3 worldPosM = worldPos + worldNormal * min(0.1 + length(worldPos) / 250.0, 0.75);

        vec3 shadowPos = mat3(shadowModelView) * worldPosM + shadowModelView[3].xyz;
             shadowPos = projMAD(shadowProjection, shadowPos);
        vec3 shadowNormal = mat3(shadowModelView) * worldNormal;

        float sampleRadius = (1.0 / shadowMapResolution) * GI_RADIUS;

        for (int i = 0; i < GI_SAMPLES; i++) {
            vec2 offset = spiralOffset((i + blueNoiseDither) * 8.0, GI_SAMPLES * 8.0) * sampleRadius;

            if (dot(shadowNormal.xy, offset) < 0.0) {
                offset = -offset;
            }

            vec2 offsetPos = shadowPos.xy + offset;
            float distb = sqrt(dot(offsetPos, offsetPos));
            float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);

            vec2 distortedPos = (offsetPos / distortFactor) * 0.5 + 0.5;

            float distortedDepth = texture2D(shadowtex1, distortedPos).r;

            vec3 samplePos = vec3(offsetPos, distortedDepth * 10.0 - 5.0);
            vec3 diffPos = samplePos - shadowPos;

            if (diffPos.z < -0.01) continue;

            float sampleLength = length(diffPos + (1.0 / GI_RADIUS)) * 16.0;

            if (sampleLength < 0.0001) continue;

            float falloff = 1.0 / mix(pow2(sampleLength), sampleLength, exp(-64.0 * sampleLength));

            vec3 sampleDirection = normalize(diffPos);
                 sampleDirection.z = -sampleDirection.z;

            float originalBounce = clamp(dot(shadowNormal, sampleDirection), 0.0, 1.0);

            if (originalBounce <= 0.0) continue;

            vec3 shadowNormal = texture2D(shadowcolor1, distortedPos).rgb * 2.0 - 1.0;
                 shadowNormal = -shadowNormal;

            float offsetBounce = clamp(dot(shadowNormal, sampleDirection), 0.0, 1.0);

            if (offsetBounce <= 0.0) continue;

            vec3 shadowColor = texture2D(shadowcolor0, distortedPos).rgb;
                 shadowColor = pow(shadowColor, vec3(2.2)) * 4.4;

            gi += offsetBounce * originalBounce * falloff * shadowColor;
        }
    }

    return gi * giDistance;
}