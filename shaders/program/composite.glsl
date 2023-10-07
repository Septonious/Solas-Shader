//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

#ifndef NETHER
in vec3 sunVec, upVec;
#endif

//Uniforms//
#if defined VL || defined VF_NETHER_END
uniform int isEyeInWater;
uniform int frameCounter;

uniform float far, near;
uniform float frameTimeCounter;
uniform float blindFactor;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

#if defined VF_NETHER_END && defined END
uniform float shadowFade;
#endif

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

#ifdef VL
uniform float timeAngle, timeBrightness, rainStrength;

uniform vec3 skyColor;
#endif
#endif

uniform sampler2D colortex0;

#if defined VL || defined VF_NETHER_END
uniform sampler2D noisetex;
uniform sampler2D colortex1;
uniform sampler2D depthtex0, depthtex1;

#if defined VL && defined SHADOW_COLOR
uniform sampler2D shadowcolor0;
#endif

#if defined VL || (defined VF_NETHER_END && defined END)
#ifdef VL
#ifdef SHADOW_COLOR
uniform sampler2DShadow shadowtex1;
#endif

uniform sampler2D shadowcolor1;
#endif

uniform sampler2DShadow shadowtex0;

uniform mat4 shadowModelView, shadowProjection;
#endif

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;
#endif

//Common Variables//
#ifdef VL
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.025, 0.0, 0.1) * 10.0;
#endif

//Includes//
#if defined VL || defined VF_NETHER_END
#include "/lib/atmosphere/spaceConversion.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/color/dimensionColor.glsl"
#endif

#if defined VL || (defined VF_NETHER_END && defined END)
#include "/lib/util/ToShadow.glsl"
#endif

#ifdef VL
#include "/lib/atmosphere/volumetricLight.glsl"
#endif

#ifdef VF_NETHER_END
#ifdef NETHER
#include "/lib/atmosphere/volumetricFog.glsl"
#endif

#ifdef END
#include "/lib/atmosphere/volumetricEndClouds.glsl"
#endif
#endif

//Program//
void main() {
	vec3 color = pow(texture2D(colortex0, texCoord).rgb, vec3(2.2));
	vec4 vl = vec4(0.0);

	#if defined VL || defined VF_NETHER_END
	vec3 translucent = texture2D(colortex1, texCoord).rgb;

	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + frameCounter * 0.618);
	#endif

	#ifdef VL
	computeVolumetricLight(vl.rgb, translucent, blueNoiseDither);
	vl.rgb = pow(vl.rgb / 128.0, vec3(0.25));
	vl.a = int(vl.rgb != vec3(0.0));
	#endif

	#ifdef VF_NETHER_END
	#ifdef NETHER
	computeVolumetricFog(vl.rgb, color, translucent, blueNoiseDither);
	vl.rgb = sqrt(vl.rgb);
	vl.a = int(vl.rgb != vec3(0.0));
	#endif

	#ifdef END
	float cloudDepth = 0.0;

	computeVolumetricClouds(vl, blueNoiseDither, cloudDepth);
	vl.rgb = sqrt(vl.rgb);
	#endif
	#endif
	#endif

	/* DRAWBUFFERS:01 */
	gl_FragData[0].rgb = color;
	gl_FragData[1] = vec4(vl.rgb, vl.a);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

#ifndef NETHER
out vec3 sunVec, upVec;
#endif

//Uniforms//
#ifndef NETHER
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Sun Vector
	#ifndef NETHER
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