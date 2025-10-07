#define SHADOW

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec4 color;
in vec3 worldPos;
in vec2 texCoord, lmCoord;
flat in int mat;

// Uniforms //
#ifdef WATER_CAUSTICS
uniform int isEyeInWater; 

uniform float frameTimeCounter;

uniform ivec2 eyeBrightnessSmooth;
uniform vec3 cameraPosition;

uniform sampler2D noisetex;
#endif

uniform sampler2D tex;

// Global Variables //
#ifdef WATER_CAUSTICS
float eBS = eyeBrightnessSmooth.y / 240.0;
#endif

// Includes //
#ifdef WATER_CAUSTICS
#include "/lib/water/waterCaustics.glsl"
#endif

// Main //
void main() {
    vec4 albedo = texture2D(tex, texCoord) * color;

	float tintedGlass = float(mat >= 10201 && mat <= 10216);
	float skyLightMap = lmCoord.y;

	if (albedo.a < 0.01) discard;

    #ifdef SHADOW_COLOR
	albedo.rgb = mix(vec3(1.0), albedo.rgb, albedo.a);
	albedo.rgb *= albedo.rgb;
	albedo.rgb *= 1.0 - pow32(albedo.a);

	#ifdef WATER_CAUSTICS
	if (mat == 10001 && lmCoord.y >= 0.01){
		float caustics = getWaterCaustics(worldPos + cameraPosition);
		albedo.rgb = vec3(0.3 + caustics * 0.7);
        albedo.rgb *= lmCoord.y;
	}
	#endif

	if (tintedGlass > 0.5 && albedo.a < 0.35) discard;
	#endif

	gl_FragData[0] = albedo;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

// VSH Data //
out vec4 color;
out vec3 worldPos;
out vec2 texCoord, lmCoord;
flat out int mat;

// Uniforms //
#ifdef VX_SUPPORT
uniform int renderStage;

#extension GL_ARB_shader_image_load_store : enable
writeonly uniform uimage3D voxel_img;
#endif

#if defined WAVING_LEAVES || defined WAVING_PLANTS
uniform float frameTimeCounter;
#endif

uniform vec3 cameraPosition;

uniform mat4 shadowProjection, shadowProjectionInverse;
uniform mat4 shadowModelView, shadowModelViewInverse;

// Attributes //
attribute vec3 at_midBlock;
attribute vec4 mc_midTexCoord;
attribute vec4 mc_Entity;

// Includes //
#ifdef VX_SUPPORT
#include "/lib/vx/voxelization.glsl"
#endif

#if defined WAVING_LEAVES || defined WAVING_PLANTS
#include "/lib/pbr/waving.glsl"
#endif

// Main //
void main() {
	texCoord = gl_MultiTexCoord0.xy;

	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));
	
	mat = int(mc_Entity.x);
	
    // Voxelization //
	#ifdef VX_SUPPORT
    if (gl_VertexID % 4 == 0) updateVoxelMap(int(mc_Entity.x - 10000));
	#endif

	//Color & Position //
	color = gl_Color;

	vec4 position = shadowModelViewInverse * shadowProjectionInverse * ftransform();

	#if defined WAVING_PLANTS || defined WAVING_LEAVES
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	position.xyz = getWavingBlocks(position.xyz, istopv, lmCoord.y);
	#endif

	worldPos = position.xyz;

	gl_Position = shadowProjection * shadowModelView * position;

	float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	float distortFactor = dist * shadowMapBias + (1.0 - shadowMapBias);
	
	gl_Position.xy *= 1.0 / distortFactor;
	gl_Position.z = gl_Position.z * 0.2;
}

#endif