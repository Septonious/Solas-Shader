void drawSunMoon(inout vec3 color, in vec3 worldPos, in vec3 nViewPos, in float VoU, in float VoS, in float VoM, in float caveFactor, in float occlusion) {
    float altitudeFactor = min(max(cameraPosition.y, 0.0) / KARMAN_LINE, 1.0);
    float visibility = (1.0 - wetness) * caveFactor * (1.0 - occlusion);
          visibility *= fmix(sqrt(max(VoU, 0.0)), 1.0, altitudeFactor);

    if (visibility > 0.0) {
        float sun = max(pow32(pow32(VoS)) - 0.4, 0.0) * 16.0 * sunVisibility;
        float moon = max(pow32(pow32(VoM)) - 0.4, 0.0);
                moon = float(moon > 0.0) * 2.0 * moonVisibility;
        float glare = pow32(VoS * sunVisibility + VoM * moonVisibility) * 0.25;

        // Moon phases and texture
        if (moon > 0.0) {
            if (moonPhase > 0) {
                float phaseFactor = int(moonPhase != 4) * (-1.0 + int(4 < moonPhase) * 2.0) * 0.003;

                const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
                float fractTimeAngle = fract(timeAngle - (0.25 + phaseFactor));
                float ang = (fractTimeAngle + (cos(fractTimeAngle * 3.14159265358979) * -0.5 + 0.5 - fractTimeAngle) / 3.0) * 6.28318530717959;
                vec3 newSunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

                moon *= 0.05 + clamp(1.0 - max(pow24(pow32(dot(nViewPos, newSunVec))) - 0.5, 0.0) * 16.0, 0.0, 1.0);
            }
        }

        color += glare * lightColSqrt * visibility * (1.0 - altitudeFactor);
        color += mix(lightCol, vec3(0.4, 0.38, 0.36), altitudeFactor) * sun * visibility;
        color += normalize(mix(lightCol, lightNight, clamp(VoU + altitudeFactor, 0.0, 1.0))) * moon * visibility;
    }
}