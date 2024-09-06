#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)

const int voxelVolumeSize = VOXEL_VOLUME_SIZE;

vec3 ToVoxel(vec3 shadowPos) {
	return shadowPos + fract(cameraPosition) + voxelVolumeSize * 0.5;
}

float getLogarithmicDepth(float dist) {
	return (far * (dist - near)) / (dist * (far - near));
}

float getLinearDepth2(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}