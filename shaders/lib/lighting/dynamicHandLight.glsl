vec3 getHandLightColor(float lViewPos) {
	float heldLightValue = max(float(heldBlockLightValue), float(heldBlockLightValue2));
	float handlight = clamp((heldLightValue - 4.0 * lViewPos) * 0.025, 0.0, 1.0);

    vec3 handLightColor = blockLightCol;

    if (handlight > 0.0) {
        if (heldItemId == 63 || heldItemId2 == 63 || heldItemId == 51 || heldItemId2 == 51 || heldItemId == 60 || heldItemId2 == 60) handLightColor = vec3(0.23, 0.54, 0.94);
        if (heldItemId == 62 || heldItemId2 == 62) handLightColor = vec3(0.70, 0.54, 0.33);
        if (heldItemId == 59 || heldItemId2 == 59) handLightColor = vec3(0.78, 0.47, 0.15);
        if (heldItemId == 58 || heldItemId2 == 58) handLightColor = vec3(0.80, 0.90, 1.20);
        if (heldItemId == 57 || heldItemId2 == 57) handLightColor = vec3(0.31, 0.44, 0.59);
        if (heldItemId == 56 || heldItemId2 == 56) handLightColor = vec3(0.86, 0.62, 0.31);
        if (heldItemId == 55 || heldItemId2 == 55) handLightColor = vec3(0.73, 0.43, 0.23);
        if (heldItemId == 54 || heldItemId2 == 54) handLightColor = vec3(1.10, 0.50, 1.50);
        if (heldItemId == 53 || heldItemId2 == 53 || heldItemId == 61 || heldItemId2 == 61 || heldItemId == 64 || heldItemId2 == 64) handLightColor = vec3(0.86, 0.62, 0.31);
        if (heldItemId == 52 || heldItemId2 == 52) handLightColor = vec3(1.00, 0.31, 0.07);
    }

    return mix(handLightColor * handlight, vec3(0.0), 0.25);
}