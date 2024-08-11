void getHandLightColor(inout vec3 blockLighting, float lViewPos) {
	float heldLightValue = max(float(heldBlockLightValue), float(heldBlockLightValue2));
	float handlight = clamp((heldLightValue - 2.0 * lViewPos) * 0.025, 0.0, 1.0);

    vec3 handLightColor = blockLightCol;

    if (handlight > 0.0) {
        if (heldItemId2 < 3) handLightColor = blocklightColorArray[heldItemId - 1];
        else handLightColor = blocklightColorArray[heldItemId2 - 1];
    }

    blockLighting += mix(handLightColor * handlight * DYNAMIC_HANDLIGHT_STRENGTH, vec3(0.0), vec3(1.0 - handlight));
}