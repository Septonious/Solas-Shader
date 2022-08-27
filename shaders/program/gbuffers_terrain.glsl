//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_TERRAIN

#ifdef FSH

//Varyings//
in float mat;
in float isPlant;
in vec2 texCoord, lightMapCoord;
in vec3 sunVec, upVec, eastVec;
in vec3 normal;

#ifdef INTEGRATED_NORMAL_MAPPING
in vec3 binormal, tangent;
#endif

in vec4 color;

//Uniforms//
uniform float viewWidth, viewHeight;
uniform float nightVision;
uniform float frameTimeCounter;

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
#include "/lib/util/bayerDithering.glsl"

#if defined OVERWORLD || defined END
#include "/lib/util/ToShadow.glsl"
#include "/lib/lighting/shadows.glsl"
#endif

#include "/lib/color/dimensionColor.glsl"
#include "/lib/lighting/sceneLighting.glsl"

#ifdef INTEGRATED_NORMAL_MAPPING
#include "/lib/ipbr/integratedNormalMapping.glsl"
#endif

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
	vec3 newNormal = normal;

	float emission = 0.0;
	float specular = 0.0;
	float roughness = 0.0;

	if (albedo.a > 0.001) {
		float foliage = float(mat > 0.99 && mat < 1.01);
		float subsurface = foliage * 0.75 + float(mat > 1.99 && mat < 2.01) * 0.75;

		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		vec3 viewPos = ToNDC(screenPos);
		vec3 worldPos = ToWorld(viewPos);
		vec2 lightmap = clamp(lightMapCoord, 0.0, 1.0);

		#ifdef INTEGRATED_NORMAL_MAPPING
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							  tangent.y, binormal.y, normal.y,
							  tangent.z, binormal.z, normal.z);

		newNormal = clamp(normalize(getIntegratedNormalMapping(albedo.rgb) * tbnMatrix), vec3(-1.0), vec3(1.0));
		#endif

		#ifdef INTEGRATED_EMISSION
		getIntegratedEmission(albedo.rgb, viewPos, worldPos, lightmap, emission);
		#endif

		#ifdef INTEGRATED_SPECULAR
		getIntegratedSpecular(albedo, newNormal, worldPos.xz, lightmap, specular, roughness);
		#endif

		getSceneLighting(albedo.rgb, viewPos, worldPos, newNormal, lightmap, emission, subsurface, foliage, specular);
	}

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;

	#ifndef INTEGRATED_SPECULAR
		#ifdef BLOOM
		/* DRAWBUFFERS:02 */
		gl_FragData[1].ba = vec2(emission * 0.01, emission);
		#endif
	#else
		/* DRAWBUFFERS:062 */
		gl_FragData[1] = vec4(albedo.rgb, roughness);
		gl_FragData[2] = vec4(EncodeNormal(newNormal), emission * 0.01, specular);
	#endif
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out float mat;
out float isPlant;
out vec2 texCoord, lightMapCoord;
out vec3 sunVec, upVec, eastVec;
out vec3 normal;

#ifdef INTEGRATED_NORMAL_MAPPING
out vec3 binormal, tangent;
#endif

out vec4 color;

//Uniforms//
#ifdef TAA
uniform int framemod8;

uniform float viewWidth, viewHeight;
#endif

#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

//Attributes//
attribute vec4 mc_Entity;

#ifdef INTEGRATED_NORMAL_MAPPING
attribute vec4 at_tangent;
#endif

//Includes//
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

	#ifdef INTEGRATED_NORMAL_MAPPING
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	#endif

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
	isPlant = 0.0;

	if (mc_Entity.x >= 4 && mc_Entity.x <= 11 && mc_Entity.x != 9 && mc_Entity.x != 10) {
		mat = 1.0;
	} else if (mc_Entity.x == 9 || mc_Entity.x == 10){
		mat = 2.0;
	} else {
		mat = float(mc_Entity.x);
	}

	#ifdef INTEGRATED_EMISSION
	#if defined EMISSIVE_FLOWERS && defined OVERWORLD
	if (mc_Entity.x == 5) isPlant = 1.0;
	#endif
	#endif

	//Color & Position
    color = gl_Color;

	gl_Position = ftransform();

	#ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif