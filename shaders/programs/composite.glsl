#define COMPOSITE_0

// Setings //
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
uniform sampler2D colortex0;

#if defined VL || defined LPV_FOG
uniform int frameCounter;
uniform int isEyeInWater;

#if defined VL && defined VC_SHADOWS
uniform int worldDay, worldTime;
#endif

uniform float shadowFade;
uniform float far, near;
#ifdef DISTANT_HORIZONS
uniform float dhFarPlane, dhNearPlane;
#endif
uniform float frameTimeCounter;
uniform float timeAngle, timeBrightness;
uniform float wetness;
uniform float blindFactor, nightVision;
#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 skyColor, cameraPosition;

#ifdef NETHER
uniform vec3 fogColor;
#endif

uniform sampler2D colortex1;
uniform sampler2D colortex3;

#ifdef LPV_FOG
uniform sampler3D floodfillSampler, floodfillSamplerCopy;
#endif

uniform sampler2D noisetex;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0, shadowtex1;
uniform sampler2D depthtex0, depthtex1;

#ifdef DISTANT_HORIZONS
uniform sampler2D dhDepthTex0, dhDepthTex1;

uniform mat4 dhProjectionInverse;
#endif

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
#endif

// Global Variables //
#if defined VL || defined LPV_FOG

const bool colortex7Clear = false;
#if defined OVERWORLD
const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
float fractTimeAngle = fract(timeAngle - 0.25);
float ang = (fractTimeAngle + (cos(fractTimeAngle * 3.14159265358979) * -0.5 + 0.5 - fractTimeAngle) / 3.0) * 6.28318530717959;
vec3 sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
#elif defined END
const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
vec3 sunVec = normalize((gbufferModelView * vec4(1.0, sunRotationData * 2000.0, 1.0)).xyz);
#else
vec3 sunVec = vec3(0.0);
#endif

vec3 upVec = normalize(gbufferModelView[1].xyz);

float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, sqrt(eBS));
float sunVisibility = clamp((dot( sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#endif

// Includes //
#if defined VL || defined LPV_FOG
#include "/lib/util/transformMacros.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/atmosphere/spaceConversion.glsl"

#if defined VL && defined VC_SHADOWS
#include "/lib/lighting/cloudShadows.glsl"
#endif

#ifdef LPV_FOG
#include "/lib/lighting/lightning.glsl"
#include "/lib/vx/voxelization.glsl"
#endif

#include "/lib/atmosphere/volumetrics.glsl"
#endif

// Main //
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#if defined VL || defined LPV_FOG
	vec3 volumetrics = vec3(0.0);

	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;
	#ifdef TAA
		  blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif

	vec3 translucent = texture2D(colortex1, texCoord).rgb;

	computeVolumetricLight(color, translucent, blueNoiseDither);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = pow(color, vec3(2.2));
}

#endif

//**//**//**//**//**//**//**//**//**//**//**//**//**//**//

#ifdef VSH

// VSH Data //
out vec2 texCoord;

// Main //
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
}

#endif