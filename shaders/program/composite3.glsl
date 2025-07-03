#define COMPOSITE_3

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;
in vec3 sunVec, upVec;

//Uniforms//
#if defined LPV_FOG || defined VL || defined FIREFLIES
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef VC_SHADOWS
uniform int worldDay, worldTime;
#endif

#ifdef DISTANT_HORIZONS
uniform int dhRenderDistance;

uniform float dhFarPlane, dhNearPlane;
#endif

uniform float viewWidth, viewHeight;
uniform float far, near;
uniform float frameTimeCounter;
uniform float timeBrightness, wetness;
uniform float blindFactor;
uniform float timeAngle, shadowFade;

#if MC_VERSION >= 12104
uniform float isPaleGarden;
#endif

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;
#endif

uniform vec3 fogColor;
uniform vec3 skyColor;

#ifdef LPV_FOG
uniform vec4 lightningBoltPosition;
#endif

uniform sampler2D colortex0;

#if defined LPV_FOG || defined VL || defined FIREFLIES
uniform sampler2D noisetex;
uniform sampler2D colortex1;
uniform sampler2D depthtex0, depthtex1;

#ifdef LPV_FOG
uniform sampler3D floodfillSampler, floodfillSamplerCopy;
#endif

#ifdef VL
#ifdef SHADOW_COLOR
uniform sampler2D shadowtex1;
#endif

uniform sampler2D shadowcolor0, shadowcolor1;
uniform sampler2D shadowtex0;

uniform mat4 shadowModelView, shadowProjection;
#endif

uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
#endif

//Common Variables//
#if defined LPV_FOG || defined VL || defined FIREFLIES
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, eBS);
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
#endif

//Includes//
#if defined LPV_FOG || defined VL || defined FIREFLIES
#include "/lib/atmosphere/spaceConversion.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToViewDH.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/bayerDithering.glsl"

#if defined LPV_FOG || defined FIREFLIES
#ifdef NETHER
#include "/lib/color/netherColor.glsl"
#endif

#ifdef LPV_FOG
#include "/lib/lighting/lightning.glsl"
#include "/lib/vx/voxelization.glsl"
#endif
#endif

#ifdef VL
#ifdef VC_SHADOWS
#include "/lib/lighting/cloudShadows.glsl"
#endif

#include "/lib/util/ToShadow.glsl"
#endif
#endif

#include "/lib/color/lightColor.glsl"
#include "/lib/atmosphere/volumetricRayMarcher.glsl"

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;
	vec4 volumetrics = vec4(0.0);

	#if defined LPV_FOG || defined VL || defined FIREFLIES
	vec3 translucent = texture2D(colortex1, texCoord).rgb;

	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;
	#ifdef TAA
		  blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif

	computeVolumetrics(volumetrics, translucent, blueNoiseDither);
	volumetrics.rgb = pow(volumetrics.rgb / 256.0, vec3(0.125));
	#endif

	/* DRAWBUFFERS:01 */
	gl_FragData[0].rgb = color;
	gl_FragData[1] = volumetrics;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;
out vec3 sunVec, upVec;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Sun Vector
	getSunVector(gbufferModelView, timeAngle, sunVec);
	upVec = normalize(gbufferModelView[1].xyz);

	//Position
	gl_Position = ftransform();
}

#endif