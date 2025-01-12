//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

#ifdef VL
in vec3 sunVec, upVec;
#endif

//Uniforms//
#if defined LPV_FOG || defined VL || defined FIREFLIES
uniform int isEyeInWater;
uniform int frameCounter;

uniform float viewWidth, viewHeight;
uniform float far, near;
uniform float frameTimeCounter;
uniform float timeBrightness, wetness;
uniform float blindFactor;

#ifdef VL
uniform float timeAngle, shadowFade;
uniform float isJungle, isSwamp;

#if MC_VERSION >= 12100
uniform float isPaleGarden;
#endif

uniform vec3 skyColor;
#endif

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;
#endif

uniform vec3 fogColor;

uniform sampler2D colortex0;

#if defined LPV_FOG || defined VL || defined FIREFLIES
uniform sampler2D noisetex;
uniform sampler2D colortex1;
uniform sampler2D depthtex0, depthtex1;

#ifdef LPV_FOG
uniform sampler3D floodfillSampler;
#endif

#ifdef VL
#ifdef SHADOW_COLOR
uniform sampler2D shadowtex1;
#endif

uniform sampler2D shadowcolor0, shadowcolor1;
uniform sampler2D shadowtex0;

uniform mat4 shadowModelView, shadowProjection;
#endif

uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
#endif

//Common Variables//
#if defined LPV_FOG || defined VL || defined FIREFLIES
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, eBS);

#ifdef VL
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
#endif
#endif

//Includes//
#if defined LPV_FOG || defined VL || defined FIREFLIES
#include "/lib/atmosphere/spaceConversion.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/bayerDithering.glsl"

#if defined LPV_FOG || defined FIREFLIES
#ifdef NETHER
#include "/lib/color/netherColor.glsl"
#endif
#ifdef DEEPERDOWN
#include "/lib/color/deeperdownColor.glsl"
#endif

#include "/lib/atmosphere/lpvFog.glsl"
#endif

#ifdef VL
#include "/lib/util/ToShadow.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/atmosphere/volumetricLight.glsl"
#endif
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;
	vec4 vl = vec4(0.0);
	float fireflies = 0.0;

	#if defined LPV_FOG || defined VL || defined FIREFLIES
	vec3 translucent = texture2D(colortex1, texCoord).rgb;

	float bayerDither = Bayer8(gl_FragCoord.xy);

	#ifdef TAA
	bayerDither = fract(bayerDither + frameTimeCounter * 16.0);
	#endif

	#ifdef FIREFLIES
	computeFireflies(fireflies, translucent, bayerDither);
	#endif

	#ifdef LPV_FOG
	computeLPVFog(vl.rgb, translucent, bayerDither);
	#endif

	#ifdef VL
	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif

	computeVL(vl.rgb, translucent, blueNoiseDither);
	#endif

	vl.rgb = pow(vl.rgb / 128.0, vec3(0.25));
	#endif

	/* DRAWBUFFERS:01 */
	gl_FragData[0].rgb = color;
	gl_FragData[1] = vec4(vl.rgb, fireflies);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

#ifdef VL
out vec3 sunVec, upVec;
#endif

//Uniforms//
#ifdef VL
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Sun Vector
	#ifdef VL
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * PI) * -0.5 + 0.5 - ang) / 3.0) * TAU;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	upVec = normalize(gbufferModelView[1].xyz);
	#endif

	//Position
	gl_Position = ftransform();
}

#endif