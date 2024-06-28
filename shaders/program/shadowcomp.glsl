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
uniform float rainStrength;
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
		int counter = 0;
		for (int i = 0; i < 6; i++) {
			light += texelFetch(floodfillSamplerCopy, clamp(previousPos + offsets[i], 0, voxelVolumeSize - 1), 0).rgb;
			counter++;
		}
		light /= counter;

		if (voxel >= 200 && voxel <= 216) {
			vec3 tint = blocklightTintArray[min(voxel - 200u, blocklightTintArray.length() - 1u)];
			light *= tint;
		}
	} else {
		#ifdef EMISSIVE_CONCRETE
		vec3 color = blocklightColorArray[min(voxel, blocklightColorArray.length() - 1u)];
	    light = color;
		#else
		if (voxel < 14 || voxel > 19) {
			vec3 color = blocklightColorArray[min(voxel, blocklightColorArray.length() - 1u)];
			light = color;
		}
		#endif

        #ifdef OVERWORLD
        if (voxel >= 34 && voxel <= 39) {
            light *= 1.0 - rainStrength;
        }
        #endif
	}

	imageStore(floodfill_img, pos, vec4(light, voxel));
}