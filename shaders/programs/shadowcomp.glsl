#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

#if VOXEL_VOLUME_SIZE == 128
const ivec3 workGroups = ivec3(16, 8, 16);
#elif VOXEL_VOLUME_SIZE == 192
const ivec3 workGroups = ivec3(24, 12, 24);
#elif VOXEL_VOLUME_SIZE == 256
const ivec3 workGroups = ivec3(32, 16, 32);
#elif VOXEL_VOLUME_SIZE == 384
const ivec3 workGroups = ivec3(48, 24, 48);
#elif VOXEL_VOLUME_SIZE == 512
const ivec3 workGroups = ivec3(64, 32, 64);
#endif

uniform int frameCounter;

#ifdef OVERWORLD
uniform float wetness;
#endif

uniform usampler3D voxelSampler;
writeonly uniform image3D floodfill_img, floodfill_img_copy;
uniform sampler3D floodfillSampler, floodfillSamplerCopy;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float frameTimeCounter;

ivec3[6] offsets = ivec3[6](
	ivec3( 1,  0,  0),
	ivec3( 0,  1,  0),
	ivec3( 0,  0,  1),
	ivec3(-1,  0,  0),
	ivec3( 0, -1,  0),
	ivec3( 0,  0, -1)
);

vec3 getFloodfill(sampler3D image, ivec3 previousPos) {
	vec3 light = texelFetch(image, previousPos, 0).rgb;
		 light += texelFetch(image, clamp(previousPos + offsets[0], 0, VOXEL_VOLUME_SIZE - 1), 0).rgb;
		 light += texelFetch(image, clamp(previousPos + offsets[1], 0, VOXEL_VOLUME_SIZE - 1), 0).rgb;
		 light += texelFetch(image, clamp(previousPos + offsets[2], 0, VOXEL_VOLUME_SIZE - 1), 0).rgb;
		 light += texelFetch(image, clamp(previousPos + offsets[3], 0, VOXEL_VOLUME_SIZE - 1), 0).rgb;
		 light += texelFetch(image, clamp(previousPos + offsets[4], 0, VOXEL_VOLUME_SIZE - 1), 0).rgb;
		 light += texelFetch(image, clamp(previousPos + offsets[5], 0, VOXEL_VOLUME_SIZE - 1), 0).rgb;
	return light / 7.01;
}

//Includes//
#include "/lib/vx/blocklightColor.glsl"
#include "/lib/vx/voxelization.glsl"

//Program//
void main() {
	ivec3 pos = ivec3(gl_GlobalInvocationID);
	ivec3 previousPos = ivec3(vec3(pos) - floor(previousCameraPosition) + floor(cameraPosition));
	uint voxel = texelFetch(voxelSampler, pos, 0).r;
	vec3 light = vec3(0.0);
	bool doFloodfill = voxel == 0 || (voxel >= 200 && voxel <= 216) || voxel == 1;

	if ((frameCounter & 1) == 0) {
		if (doFloodfill) {
			light = getFloodfill(floodfillSampler, previousPos);
		}
	} else {
		if (doFloodfill) {
			light = getFloodfill(floodfillSamplerCopy, previousPos);
		}
	}

	if (voxel >= 200 && voxel <= 216) {
		vec3 tint = blocklightTintArray[min(voxel - 200u, blocklightTintArray.length() - 1u)];
		light *= pow(tint, vec3(FLOODFILL_RADIUS));
	}

	if (!doFloodfill) {
		vec3 color = getBlocklightColor(int(voxel) + 1);
		light = pow(color, vec3(FLOODFILL_RADIUS));

		#ifdef OVERWORLD
		if (voxel >= 34 && voxel <= 39) {
			light *= 1.0 - wetness;
		}
		#endif
	}

	if ((frameCounter & 1) == 0) {
		imageStore(floodfill_img_copy, pos, vec4(light, voxel));
	} else {
		imageStore(floodfill_img, pos, vec4(light, voxel));
	}
}