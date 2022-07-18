//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_TERRAIN

#ifdef FSH

//Varyings//
in float mat;

#ifdef INTEGRATED_EMISSION
in float isPlant;
#endif

in vec2 texCoord, lightMapCoord;
in vec3 sunVec, upVec, eastVec;
in vec3 normal;
in vec4 color;

//Uniforms//
uniform float viewWidth, viewHeight;
uniform float nightVision;

#ifdef INTEGRATED_EMISSION
uniform float frameTimeCounter;
#endif

#ifdef OVERWORLD
uniform float rainStrength;
#endif

#if defined OVERWORLD || defined END
uniform float timeBrightness, timeAngle;
#endif

#ifdef RAIN_PUDDLES
uniform float wetness;

uniform sampler2D noisetex;
#endif

uniform vec3 cameraPosition;

uniform sampler2D texture;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

#if defined OVERWORLD || defined END
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
#endif

//Common Variables//
#ifdef OVERWORLD
float sunVisibility = clamp((dot(sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
#endif

//Includes//
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"

#if defined OVERWORLD || defined END
#include "/lib/util/ToShadow.glsl"
#include "/lib/lighting/shadows.glsl"
#endif

#include "/lib/color/dimensionColor.glsl"
#include "/lib/lighting/sceneLighting.glsl"

#ifdef INTEGRATED_EMISSION
#include "/lib/ipbr/integratedEmissionTerrain.glsl"
#endif

#ifdef INTEGRATED_SPECULAR
#include "/lib/ipbr/integratedSpecular.glsl"
#endif

#if defined BLOOM || defined INTEGRATED_SPECULAR
#include "/lib/util/encode.glsl"
#endif

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;
	float subsurface = float(mat > 0.99 && mat < 1.01);
	float emission = 0.0;
	float specular = 0.0;
	float roughness = 0.0;

	if (albedo.a > 0.0001) {
		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		vec3 viewPos = ToNDC(screenPos);
		vec3 worldPos = ToWorld(viewPos);
		vec2 lightmap = clamp(lightMapCoord, vec2(0.0), vec2(1.0));

		#ifdef INTEGRATED_EMISSION
		getIntegratedEmission(albedo.rgb, worldPos, lightmap, emission);
		#endif

		#ifdef INTEGRATED_SPECULAR
		getIntegratedSpecular(albedo, normal, worldPos.xz, lightmap, specular, roughness);
		#endif

		getSceneLighting(albedo.rgb, viewPos, worldPos, normal, lightmap, emission, subsurface, specular);
	}

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;

	#ifndef INTEGRATED_SPECULAR
		#if defined BLOOM || defined INTEGRATED_SPECULAR
		/* DRAWBUFFERS:02 */
		gl_FragData[1] = vec4(EncodeNormal(normal), specular, emission);
		#endif
	#else
		/* DRAWBUFFERS:06 */
		gl_FragData[1] = vec4(albedo.rgb, roughness);

		#if defined BLOOM || defined INTEGRATED_SPECULAR
		/* DRAWBUFFERS:062 */
		gl_FragData[2] = vec4(EncodeNormal(normal), specular, emission);
		#endif
	#endif
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out float mat;

#ifdef INTEGRATED_EMISSION
out float isPlant;
#endif

out vec2 texCoord, lightMapCoord;
out vec3 sunVec, upVec, eastVec;
out vec3 normal;
out vec3 glPos;
out vec4 color;

//Uniforms//
#ifdef TAA
uniform int frameCounter;

uniform float viewWidth, viewHeight;
#endif

#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

//Attributes//
attribute vec4 mc_Entity;

//Includes//
#ifdef INTEGRATED_EMISSION
#include "/lib/ipbr/integratedEmissionTerrain.glsl"
#endif

#ifdef INTEGRATED_SPECULAR
#include "/lib/ipbr/integratedSpecular.glsl"
#endif

#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

//Program//
void main() {
	//Coord
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	lightMapCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lightMapCoord = clamp((lightMapCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Normal
	normal = normalize(gl_NormalMatrix * gl_Normal);

	//Sun & Other vectors
    #if defined OVERWORLD
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
    #elif defined END
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
    sunVec = normalize((gbufferModelView * vec4(vec3(0.0, sunRotationData * 2000.0), 1.0)).xyz);
    #endif
	
	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

	//Materials
	mat = 0.0;

	if (mc_Entity.x >= 4 && mc_Entity.x <= 13) mat = 1.0;

	#ifdef INTEGRATED_EMISSION
	isPlant = 0.0;
	getIntegratedEmissionMaterials(mat, isPlant);
	#endif

	#ifdef INTEGRATED_SPECULAR
	getIntegratedSpecularMaterials(mat);
	#endif

	//Color & Position
    color = gl_Color;

	gl_Position = ftransform();

	#ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif