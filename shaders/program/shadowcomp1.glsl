#include "/lib/common.glsl"

#if VOXEL_VOLUME_SIZE == 64
const ivec3 workGroups = ivec3(2, 64, 64);
#elif VOXEL_VOLUME_SIZE == 128
const ivec3 workGroups = ivec3(4, 128, 128);
#elif VOXEL_VOLUME_SIZE == 256
const ivec3 workGroups = ivec3(8, 256, 256);
#elif VOXEL_VOLUME_SIZE == 512
const ivec3 workGroups = ivec3(16, 512, 512);
#endif

layout (local_size_x = 32) in;

writeonly uniform image3D floodfill_img_copy;
uniform sampler3D floodfillSampler;

void main() {
	ivec3 pos = ivec3(gl_GlobalInvocationID);
	vec4 light = texelFetch(floodfillSampler, pos, 0);
	imageStore(floodfill_img_copy, pos, light);
}