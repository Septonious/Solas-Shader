#define DH_TERRAIN
#define GBUFFERS_TERRAIN

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
flat in int mat;
in vec2 texCoord, lmCoord;
in vec3 normal, binormal, tangent;
in vec3 eastVec, northVec, sunVec, upVec;
in vec4 color;

//Uniforms//
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef VC
uniform int worldDay;
#endif

#ifdef DYNAMIC_HANDLIGHT
uniform int heldItemId, heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
#endif

#ifdef AURORA
uniform int moonPhase;
uniform float isSnowy;
#endif

uniform float far;

uniform float frameTimeCounter;
uniform float viewWidth, viewHeight;
uniform float blindFactor;
uniform float nightVision;

#ifdef OVERWORLD
uniform float timeBrightness, timeAngle;
uniform float shadowFade;
uniform float wetness;
#endif

uniform ivec2 eyeBrightnessSmooth;
uniform ivec2 atlasSize;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec3 cameraPosition;

#ifdef GI
uniform vec3 previousCameraPosition;

uniform sampler2D gaux1;
#endif

uniform sampler2D texture;
uniform sampler2D noisetex;

uniform sampler3D floodfillSampler;
uniform usampler3D voxelSampler;

#ifdef GI
uniform mat4 gbufferPreviousModelView;
uniform mat4 dhPreviousProjection;
#endif

uniform mat4 dhProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

//Common Variables//
#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
vec3 lightVec = sunVec;
#endif

mat4 gbufferProjectionInverse = dhProjectionInverse;

#ifdef GI
mat4 gbufferPreviousProjection = dhPreviousProjection;
#endif

//Common Functions//
float GetLuminance(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float GetBlueNoise3D(vec3 pos, vec3 normal) {
	pos = (floor(pos + 0.01) + 0.5) / 512.0;

	vec3 worldNormal = (gbufferModelViewInverse * vec4(normal, 0.0)).xyz;
	vec3 noise3D = vec3(
		texture2D(noisetex, pos.yz).b,
		texture2D(noisetex, pos.xz).b,
		texture2D(noisetex, pos.xy).b
	);

	float noiseX = noise3D.x * abs(worldNormal.x);
	float noiseY = noise3D.y * abs(worldNormal.y);
	float noiseZ = noise3D.z * abs(worldNormal.z);
	float noise = noiseX + noiseY + noiseZ;

	return noise - 0.5;
}


//Includes//
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/encode.glsl"
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/color/netherColor.glsl"
#include "/lib/vx/blocklightColor.glsl"
#include "/lib/vx/voxelization.glsl"
#include "/lib/pbr/ggx.glsl"
#include "/lib/lighting/shadows.glsl"

#ifdef GI
#include "/lib/util/reprojection.glsl"
#endif

#include "/lib/lighting/gbuffersLighting.glsl"

#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

//Program//
void main() {
	vec4 albedo = color;

	vec3 newNormal = normal;

	float leaves = float(mat == 10314);
	float foliage2 = float(mat == 10317);
	float foliage = float(mat >= 10304 && mat <= 10319 || mat >= 35 && mat <= 40) * (1.0 - leaves) * (1.0 - foliage2);
	float other = float(mat == 20312);
	float subsurface = foliage + leaves * 0.5 + other * 0.4 + foliage2 * 0.3;
    float smoothness = 0.0, metalness = 0.0;
	float emission = 0.0;

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	#ifdef TAA
	vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
	#else
	vec3 viewPos = ToNDC(screenPos);
	#endif
	vec3 worldPos = ToWorld(viewPos);
	vec2 lightmap = clamp(lmCoord, 0.0, 1.0);

	float dither = Bayer8(gl_FragCoord.xy);

	float minDist = (dither - 1.0) * 16.0 + far;
	if (length(viewPos) < minDist) {
		discard;
		return;
	}

	vec3 noisePos = (worldPos + cameraPosition) * 4.0;
	float albedoLuma = GetLuminance(albedo.rgb);
	float noiseAmount = (1.0 - albedoLuma * albedoLuma) * 0.05;
	float albedoNoise = GetBlueNoise3D(noisePos, normal);
	albedo.rgb = clamp(albedo.rgb + albedoNoise * noiseAmount, vec3(0.0), vec3(1.0));

	if (foliage > 0.5) {
		newNormal = upVec;
	}

	float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
	float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
	float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

	float parallaxShadow = 1.0;

	vec3 shadow = vec3(0.0);
	gbuffersLighting(albedo, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, subsurface, smoothness, emission, parallaxShadow);

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
flat out int mat;
out vec2 texCoord, lmCoord;
out vec3 normal, binormal, tangent;
out vec3 eastVec, northVec, sunVec, upVec;
out vec4 color;

//Uniforms//
#ifdef TAA
uniform float viewWidth, viewHeight;
#endif

#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

#if defined WAVING_LEAVES || defined WAVING_PLANTS
uniform float frameTimeCounter;
uniform float rainStrength;

uniform vec3 cameraPosition;
#endif

uniform mat4 dhProjection;
uniform mat4 gbufferModelView, gbufferModelViewInverse;

//Attributes//
attribute vec4 at_tangent;
attribute vec4 mc_midTexCoord;

//Includes
#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

#if defined WAVING_LEAVES || defined WAVING_PLANTS
#include "/lib/util/waving.glsl"
#endif

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Normal, Binormal and Tangent
	normal = normalize(gl_NormalMatrix * gl_Normal);
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent = normalize(gl_NormalMatrix * at_tangent.xyz);

	//Sun & Other vectors
	#if defined OVERWORLD || defined END
	sunVec = getSunVector(gbufferModelView, timeAngle);
	#endif

	upVec = normalize(gbufferModelView[1].xyz);
	northVec = normalize(gbufferModelView[2].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

	//Materials
	mat = 0;

	if (dhMaterialId == DH_BLOCK_LEAVES) {
		mat = 10314;
	}

	//Color & Position
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	/*
	#if defined WAVING_PLANTS || defined WAVING_LEAVES
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	position.xyz = getWavingBlocks(position.xyz, istopv, lmCoord.y);
	#endif
	*/

	color = gl_Color;

	gl_Position = dhProjection * gbufferModelView * position;

	#ifdef TAA
	if (!(mat >= 10035 && mat <= 10040)) gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif