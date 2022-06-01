//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_0

#ifdef FSH

//Varyings//
varying vec2 texCoord;

#if defined VL || defined VCLOUDS
varying vec3 sunVec, upVec;
#endif

//Uniforms//
#if defined VL || defined VCLOUDS
uniform int isEyeInWater;

uniform float frameTimeCounter;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform float far, near;
uniform float timeBrightness, timeAngle, rainStrength, blindFactor;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;

uniform sampler2D colortex1;
uniform sampler2D depthtex2;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
#endif

#ifdef VL
uniform mat4 shadowModelView, shadowProjection;

uniform sampler2DShadow shadowtex0;

#ifdef SHADOW_COLOR
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
#endif
#endif

//Common Variables//
#if defined VL || defined VCLOUDS
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;

float eBS = eyeBrightnessSmooth.y / 240.0;
float ug = mix(clamp((cameraPosition.y - 32.0) / 16.0, 0.0, 1.0), 1.0, eBS) * (1.0 - blindFactor);
#endif

//Includes//
#if defined VL || defined VCLOUDS
#include "/lib/color/lightColor.glsl"
#include "/lib/util/blueNoise.glsl"
#include "/lib/atmosphere/spaceConversion.glsl"
#endif

#ifdef VL
#include "/lib/atmosphere/volumetricLight.glsl"
#endif

#ifdef VCLOUDS
#include "/lib/atmosphere/3DNoise.glsl"
#include "/lib/atmosphere/volumetricClouds.glsl"
#endif

//Program//
void main() {
	vec3 vl = vec3(0.0);
	vec4 clouds = vec4(0.0);

	#if defined VL || defined VCLOUDS
	vec2 newTexCoord = texCoord * VOLUMETRICS_RENDER_SCALE;
	vec3 translucent = texture2D(colortex1, newTexCoord).rgb;

	float z0 = texture2D(depthtex0, newTexCoord).r;
	float z1 = texture2D(depthtex1, newTexCoord).r;

	vec4 screenPos = vec4(newTexCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	float VoL = clamp(dot(normalize(viewPos.xyz), sunVec), 0.0, 1.0);
	float dither = getBlueNoise(gl_FragCoord.xy);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif
	#endif

	#ifdef VL
	vl = getVolumetricLight(viewPos.xyz, newTexCoord, z0, z1, translucent, dither);
	vl *= mix(0.5 + VoL * 0.25, pow2(VoL) * 2.0, timeBrightness) * (1.0 - rainStrength * 0.75) * (1.0 - blindFactor) * (0.5 + sunVisibility * 0.5);

	#if MC_VERSION >= 11900
	vl *= 1.0 - darknessFactor;
	#endif
	#endif

	#ifdef VCLOUDS
	clouds = getVolumetricCloud(viewPos.xyz, newTexCoord, z0, z1, translucent, dither);
	clouds.rgb *= 1.0 + timeBrightness * 0.75 + pow8(VoL) * 0.25;
	clouds.a *= 1.0 - rainStrength * 0.1;

	#if MC_VERSION >= 11900
	clouds *= 1.0 - darknessFactor;
	#endif
	#endif

    /*DRAWBUFFERS:14*/
	gl_FragData[0].rgb = vl;
	gl_FragData[1] = clouds;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
varying vec2 texCoord;

#if defined VL || defined VCLOUDS
varying vec3 sunVec, upVec;
#endif

//Uniforms//
#if defined VL || defined VCLOUDS
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.xy;
	
	#if defined VL || defined VCLOUDS
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
	#endif

	gl_Position = ftransform();
}

#endif