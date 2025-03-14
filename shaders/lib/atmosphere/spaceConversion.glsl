#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)

const vec3 voxelVolumeSize = vec3(VOXEL_VOLUME_SIZE, VOXEL_VOLUME_SIZE * 0.5, VOXEL_VOLUME_SIZE);

vec3 worldToVoxel(vec3 worldPos) {
	return worldPos + fract(cameraPosition) + voxelVolumeSize * 0.5;
}

float getLogarithmicDepth(float dist) {
	return (far * (dist - near)) / (dist * (far - near));
}

float getLinearDepth2(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}