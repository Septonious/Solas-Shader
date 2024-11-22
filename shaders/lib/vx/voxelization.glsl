const vec3 voxelVolumeSize = vec3(VOXEL_VOLUME_SIZE);

vec3 ToVoxel(vec3 shadowPos) {
	return shadowPos + fract(cameraPosition) + voxelVolumeSize * 0.5;
}

vec3 voxelToWorld(vec3 voxelPos) {
	return voxelPos - fract(cameraPosition) - voxelVolumeSize * 0.5;
}

bool isInsideVoxelVolume(vec3 voxelPos) {
	voxelPos /= voxelVolumeSize;

	return clamp(voxelPos, 0.0, 1.0) == voxelPos;
}

#ifdef SHADOW
void updateVoxelMap(uint id) {
	vec3 modelPos = gl_Vertex.xyz + at_midBlock / 64.0;
	vec3 viewPos  = mat3(gl_ModelViewMatrix) * modelPos + gl_ModelViewMatrix[3].xyz;
	vec3 shadowPos = mat3(shadowModelViewInverse) * viewPos + shadowModelViewInverse[3].xyz;
	vec3 voxelPos = ToVoxel(shadowPos);

	bool terrain = id != 1 && any(equal(ivec4(renderStage), ivec4(MC_RENDER_STAGE_TERRAIN_SOLID, MC_RENDER_STAGE_TERRAIN_TRANSLUCENT, MC_RENDER_STAGE_TERRAIN_CUTOUT, MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED)));

	if (terrain && isInsideVoxelVolume(voxelPos)) {
		imageStore(voxel_img, ivec3(voxelPos), uvec4(max(id - 1, 1), uvec3(0u)));
	}
}
#endif