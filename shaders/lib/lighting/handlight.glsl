uniform vec3 relativeEyePosition;

void getHandLightColor(inout vec3 blockLighting, in vec3 normal, in vec3 pos) {
    if ((heldItemId >= 1 && heldItemId <= 60) || (heldItemId2 >= 1 && heldItemId2 <= 60)) {
        float handlight = clamp((32.0 - length(pos) * 5.0) * 0.015, 0.0, 1.0);

        vec3 color1 = blocklightColorArray[clamp(heldItemId - 1, 0, blocklightColorArray.length() - 1)];
        vec3 color2 = blocklightColorArray[clamp(heldItemId2 - 1, 0, blocklightColorArray.length() - 1)];

        vec3 handLightColor = mix(color1, color2, 0.5);


        vec3 lighting = handLightColor * pow3(handlight) * DYNAMIC_HANDLIGHT_STRENGTH;
        blockLighting += lighting;
    }
}