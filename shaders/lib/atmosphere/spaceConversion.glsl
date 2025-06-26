#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)

float getLogarithmicDepth(float dist) {
	float far2 = far;
	float near2 = near;

	#ifdef DISTANT_HORIZONS
	far2 = max(far, dhFarPlane);
	near2 = min(near, dhNearPlane);
	#endif

	return (far2 * (dist - near2)) / (dist * (far2 - near2));
}

float getLinearDepth2(float depth) {
	float far2 = far;
	float near2 = near;

	#ifdef DISTANT_HORIZONS
	far2 = max(far, dhFarPlane);
	near2 = min(near, dhNearPlane);
	#endif

    return 2.0 * near2 * far2 / (far2 + near2 - (2.0 * depth - 1.0) * (far2 - near2));
}