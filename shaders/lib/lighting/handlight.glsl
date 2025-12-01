uniform int heldItemId, heldItemId2;
uniform vec3 relativeEyePosition;

vec3 getHandLightColor(inout vec3 blockLighting, in vec3 pos) {
    vec3 lighting = vec3(0.0);

    if ((heldItemId >= 1 && heldItemId <= 83) || (heldItemId2 >= 1 && heldItemId2 <= 83)) {
        float handlight = clamp((32.0 - length(pos) * 5.0) * 0.015, 0.0, 1.0);

        vec3 color1 = getBlocklightColor(heldItemId);
        vec3 color2 = getBlocklightColor(heldItemId2);

        lighting = mix(color1, color2, vec3(0.5)) * pow3(handlight) * DYNAMIC_HANDLIGHT_STRENGTH;

        #ifdef GBUFFERS_HAND
        lighting *= 2.0;
        #endif
    }

    return clamp(lighting, vec3(0.0), vec3(4.0));
}