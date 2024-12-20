void getHandLightColor(inout vec3 blockLighting, in vec3 normal, in vec3 pos) {
    if (heldItemId >= 1 || heldItemId2 >= 1) {
        float handlight = clamp((32.0 - length(pos) * 5.0) * 0.015, 0.0, 1.0);

        vec3 color1 = blocklightColorArray[heldItemId - 1];
        vec3 color2 = blocklightColorArray[heldItemId2 - 1];
        vec3 handLightColor = mix(normalize(color1 + 0.0001), normalize(color2 + 0.0001), 0.5);
            handLightColor *= handLightColor;
            handLightColor *= length(color1) + length(color2);

        vec3 lighting = mix(handLightColor * handlight * DYNAMIC_HANDLIGHT_STRENGTH, vec3(0.0), vec3(1.0 - handlight));
        blockLighting += lighting;
    }
}