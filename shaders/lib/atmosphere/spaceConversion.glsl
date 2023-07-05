#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)

#if (defined VL && !defined DEFERRED) || defined VF_NETHER_END
float getLogarithmicDepth(float dist) {
	return (far * (dist - near)) / (dist * (far - near));
}

float getLinearDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}
#endif