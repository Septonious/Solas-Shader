//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

#if defined VC || defined VL
in vec3 sunVec, upVec;
#endif

//Uniforms//
#if defined VC || defined VL
uniform int isEyeInWater;

#ifdef VL
uniform float near;
#endif

uniform float far;
uniform float frameTimeCounter;
uniform float timeAngle, timeBrightness;
uniform float rainStrength, blindFactor, shadowFade;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition, skyColor;
#endif

uniform sampler2D colortex0;

#if defined VC || defined VL
uniform sampler2D noisetex;
uniform sampler2D colortex1;
uniform sampler2D depthtex0, depthtex1;
uniform sampler2D shadowcolor1;

#if (defined VC || defined VL) && defined SHADOW_COLOR
uniform sampler2D shadowcolor0;
#endif

uniform sampler2DShadow shadowtex0, shadowtex1;

uniform mat4 shadowModelView, shadowProjection;
uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;
#endif

//Common Variables//
#if defined VC || defined VL
float eBS = sqrt(eyeBrightnessSmooth.y / 240.0);
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(isEyeInWater == 1), 1.0), 1.0, eBS);
float sunVisibility = clamp(dot(sunVec, upVec) + 0.025, 0.0, 0.1) * 10.0;
#endif

//Includes//
#if defined VC || defined VL
#include "/lib/color/lightColor.glsl"
#include "/lib/util/blueNoiseDithering.glsl"
#include "/lib/atmosphere/spaceConversion.glsl"
#include "/lib/atmosphere/volumetricEffects.glsl"
#endif

//Program//
void main() {
	vec3 color = pow(texture2D(colortex0, texCoord).rgb, vec3(2.2));
	vec3 vl = vec3(0.0);
	vec4 vc = vec4(0.0);

	#if defined VC || defined VL
	vec3 translucent = texture2D(colortex1, texCoord).rgb;

	float dither = getBlueNoise(gl_FragCoord.xy);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

	#ifdef VC
	computeVolumetricClouds(vc, dither, caveFactor);
	#endif

	#ifdef VL
	computeVolumetricLight(vl, translucent, dither);
	#endif

	color = mix(color, vc.rgb, pow4(vc.a) * VC_OPACITY);
	color += vl;
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

#if defined VC || defined VL
out vec3 sunVec, upVec;
#endif

//Uniforms//
#if defined VC || defined VL
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Sun Vector
	#if defined VC || defined VL
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