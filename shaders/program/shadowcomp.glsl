#include "/lib/common.glsl"

layout (local_size_x = 32) in;

#if VOXEL_VOLUME_SIZE == 64
const ivec3 workGroups = ivec3(2, 64, 64);
#elif VOXEL_VOLUME_SIZE == 128
const ivec3 workGroups = ivec3(4, 128, 128);
#elif VOXEL_VOLUME_SIZE == 256
const ivec3 workGroups = ivec3(8, 256, 256);
#elif VOXEL_VOLUME_SIZE == 512
const ivec3 workGroups = ivec3(16, 512, 512);
#endif

#ifdef OVERWORLD
uniform float wetness;
#endif

writeonly uniform image3D floodfill_img;

uniform usampler3D voxelSampler;
uniform sampler3D floodfillSamplerCopy;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

ivec3[6] offsets = ivec3[6](
	ivec3( 1,  0,  0),
	ivec3( 0,  1,  0),
	ivec3( 0,  0,  1),
	ivec3(-1,  0,  0),
	ivec3( 0, -1,  0),
	ivec3( 0,  0, -1)
);

#include "/lib/vx/blocklightColor.glsl"
#include "/lib/vx/voxelization.glsl"

void main() {
	ivec3 pos = ivec3(gl_GlobalInvocationID);
	ivec3 previousPos = ivec3(vec3(pos) - floor(previousCameraPosition) + floor(cameraPosition));
	uint voxel = texelFetch(voxelSampler, pos, 0).r;
	vec3 light = vec3(0.0);

	if (voxel == 0 || (voxel >= 200 && voxel <= 216) || voxel == 1) {
		light  = texelFetch(floodfillSamplerCopy, previousPos, 0).rgb;
		light += texelFetch(floodfillSamplerCopy, clamp(previousPos + offsets[0], 0, VOXEL_VOLUME_SIZE - 1), 0).rgb;
		light += texelFetch(floodfillSamplerCopy, clamp(previousPos + offsets[1], 0, VOXEL_VOLUME_SIZE - 1), 0).rgb;
		light += texelFetch(floodfillSamplerCopy, clamp(previousPos + offsets[2], 0, VOXEL_VOLUME_SIZE - 1), 0).rgb;
		light += texelFetch(floodfillSamplerCopy, clamp(previousPos + offsets[3], 0, VOXEL_VOLUME_SIZE - 1), 0).rgb;
		light += texelFetch(floodfillSamplerCopy, clamp(previousPos + offsets[4], 0, VOXEL_VOLUME_SIZE - 1), 0).rgb;
		light += texelFetch(floodfillSamplerCopy, clamp(previousPos + offsets[5], 0, VOXEL_VOLUME_SIZE - 1), 0).rgb;
		light /= 7.1;

		if (voxel >= 200 && voxel <= 216) {
			vec3 tint = blocklightTintArray[min(voxel - 200u, blocklightTintArray.length() - 1u)];
			light *= pow(tint, vec3(FLOODFILL_RADIUS));
		}
	} else {
		vec3 color = blocklightColorArray[min(voxel, blocklightColorArray.length() - 1u)];
	    light = pow(color, vec3(FLOODFILL_RADIUS));

        #ifdef OVERWORLD
        if (voxel >= 34 && voxel <= 39) {
            light *= 1.0 - wetness;
        }
        #endif
	}

	imageStore(floodfill_img, pos, vec4(light, voxel));
}