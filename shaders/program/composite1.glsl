//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

#if defined OVERWORLD || defined END
in vec3 sunVec, upVec;
#endif

//Uniforms//
#ifdef INTEGRATED_SPECULAR
uniform int isEyeInWater;

#ifdef OVERWORLD
uniform int moonPhase;

uniform float timeBrightness, timeAngle, rainStrength;
#endif

#if REFLECTION_TYPE == 1
uniform float viewHeight, viewWidth;
#endif

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform float far, frameTimeCounter;
uniform float blindFactor;

#ifdef AURORA
uniform float isSnowy;
#endif

#ifdef RAINBOW
uniform float wetness;
#endif

#if defined OVERWORLD || defined END
uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;
#endif

#ifdef OVERWORLD
uniform vec3 skyColor;
#endif

uniform sampler2D colortex2, colortex6;
#endif

uniform sampler2D colortex0;

#ifdef INTEGRATED_SPECULAR
uniform sampler2D noisetex;

#if REFLECTION_TYPE == 1
uniform sampler2D depthtex1;
#endif

#ifdef NEBULA
uniform sampler2D depthtex0;
#endif

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

#ifdef OVERWORLD
uniform mat4 gbufferModelView;
#endif
#endif

//Common Variables//
#if (defined OVERWORLD || defined END) && defined INTEGRATED_SPECULAR
float eBS = eyeBrightnessSmooth.y / 240.0;
float ug = mix(clamp((cameraPosition.y - 56.0) / 16.0, 0.0, 1.0), 1.0, eBS);
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
#endif

#if REFLECTION_TYPE == 1 && defined INTEGRATED_SPECULAR
vec2 viewResolution = vec2(viewWidth, viewHeight);
#endif

//Optifine Constants//
#ifdef INTEGRATED_SPECULAR
const bool colortex6MipmapEnabled = true;
#endif

//Includes//
#ifdef INTEGRATED_SPECULAR
#include "/lib/util/ToScreen.glsl"
#include "/lib/util/encode.glsl"

#if REFLECTION_TYPE == 1
#include "/lib/util/blueNoiseDithering.glsl"
#include "/lib/util/raytracer.glsl"
#endif

#include "/lib/color/dimensionColor.glsl"

#ifdef OVERWORLD
#include "/lib/util/bayerDithering.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/sunMoon.glsl"
#endif

#if defined OVERWORLD || defined END
#include "/lib/atmosphere/skyEffects.glsl"
#endif

#include "/lib/ipbr/reflection.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef INTEGRATED_SPECULAR
	float z0 = texture2D(depthtex0, texCoord).r;
	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec4 terrainData = texture2D(colortex2, texCoord);
	vec3 normal = DecodeNormal(terrainData.rg);
	float specular = terrainData.b;
	float emissive = terrainData.a;

	if (specular > 0.05 && emissive != 0.01 && z0 > 0.56 && isEyeInWater == 0) {
		float fresnel = clamp(pow4(1.0 + dot(normal, normalize(viewPos.xyz))), 0.0, 1.0);

		vec3 reflection = getReflection(viewPos.xyz, normal, color);
		color = mix(color, reflection, fresnel * specular);
	}
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

#if defined OVERWORLD || defined END
out vec3 sunVec, upVec;
#endif

//Uniforms
#if defined OVERWORLD || defined END
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Sun & Other Vectors
    #if defined OVERWORLD
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
    #elif defined END
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
    sunVec = normalize((gbufferModelView * vec4(vec3(0.0, sunRotationData * 2000.0), 1.0)).xyz);
    #endif

	#if defined OVERWORLD || defined END
	upVec = normalize(gbufferModelView[1].xyz);
	#endif

	//Position
	gl_Position = ftransform();
}

#endif