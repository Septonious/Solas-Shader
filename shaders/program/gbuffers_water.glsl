//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_WATER

#ifdef FSH

//Varyings//
#ifdef WATER_NORMALS
in float viewDistance;
#endif

in float mat;
in vec2 texCoord, lightMapCoord;
in vec3 sunVec, upVec, eastVec;
in vec3 normal;

#ifdef WATER_NORMALS
in vec3 viewVector, binormal, tangent;
#endif

in vec4 color;

//Uniforms//
uniform int isEyeInWater;

#ifdef DYNAMIC_HANDLIGHT
uniform int heldItemId, heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
#endif

#ifdef INTEGRATED_SPECULAR
#ifdef OVERWORLD
uniform int moonPhase;
#endif

#ifdef AURORA
uniform float isSnowy;
#endif

#ifdef RAINBOW
uniform float wetness;
#endif
#endif

uniform float viewWidth, viewHeight, far;
uniform float nightVision, blindFactor;
uniform float frameTimeCounter;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

#ifdef OVERWORLD
uniform float rainStrength;
#endif

#if defined OVERWORLD || defined END
uniform float timeBrightness, timeAngle;
#endif

#if defined OVERWORLD || ((defined OVERWORLD || defined END) && defined INTEGRATED_SPECULAR)
uniform ivec2 eyeBrightnessSmooth;
#endif

uniform vec3 cameraPosition;

#ifdef OVERWORLD
uniform vec3 skyColor, fogColor;
#endif

#if defined WATER_NORMALS || (defined INTEGRATED_SPECULAR && (defined END_NEBULA || defined AURORA))
uniform sampler2D noisetex;

#ifndef BLOCKY_CLOUDS
uniform sampler2D shadowcolor1;
#endif
#endif

#ifdef INTEGRATED_SPECULAR
uniform sampler2D gaux3;
#endif

#if defined BLOOM_COLORED_LIGHTING || defined GLOBAL_ILLUMINATION
uniform sampler2D gaux4;
#endif

#ifdef VC
uniform sampler2D gaux1;
#endif

uniform sampler2D texture;

#if defined WATER_FOG || defined INTEGRATED_SPECULAR
uniform sampler2D depthtex1;
#endif

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

#ifdef INTEGRATED_SPECULAR
#ifdef OVERWORLD
uniform mat4 gbufferModelView;
#endif

uniform mat4 gbufferProjection;
#endif

#if defined OVERWORLD || defined END
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
#endif

//Common Variables//
#if defined BLOOM_COLORED_LIGHTING || defined GLOBAL_ILLUMINATION
float getLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}
#endif

#if defined OVERWORLD || ((defined OVERWORLD || defined END) && defined INTEGRATED_SPECULAR)
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(isEyeInWater == 1), 1.0), 1.0, eBS);

#ifdef OVERWORLD
float sunVisibility = clamp(dot(sunVec, upVec) + 0.025, 0.0, 0.1) * 10.0;
#endif
#endif

#ifdef INTEGRATED_SPECULAR
vec2 viewResolution = vec2(viewWidth, viewHeight);
#endif

//Includes//
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/bayerDithering.glsl"

#ifdef INTEGRATED_SPECULAR
#include "/lib/util/ToScreen.glsl"
#include "/lib/util/raytracer.glsl"
#endif

#if defined OVERWORLD || defined END
#include "/lib/util/ToShadow.glsl"
#include "/lib/lighting/shadows.glsl"
#endif

#include "/lib/color/dimensionColor.glsl"
#include "/lib/lighting/sceneLighting.glsl"

#if defined OVERWORLD && defined INTEGRATED_SPECULAR
#include "/lib/atmosphere/sky.glsl"
#endif

#ifdef WATER_NORMALS
#include "/lib/water/waterNormals.glsl"
#endif

#include "/lib/atmosphere/fog.glsl"

#ifdef INTEGRATED_SPECULAR
#ifdef OVERWORLD
#include "/lib/atmosphere/sunMoon.glsl"
#endif

#if defined OVERWORLD || defined END
#include "/lib/atmosphere/skyEffects.glsl"
#endif

#include "/lib/ipbr/waterReflection.glsl"
#endif

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;

	float water = float(mat > 0.9 && mat < 1.1);
	float portal = float(mat > 1.9 && mat < 2.1);
	float emission = portal * 4.0;

	albedo.a *= 1.0 - portal * 0.5;

	#ifndef VANILLA_WATER
	if (water > 0.9) {
		albedo.a = WATER_A;
		#ifdef OVERWORLD
		albedo.rgb = mix(waterColor, weatherCol.rgb * 0.25, rainStrength * 0.5);
		#else
		albedo.rgb = waterColor;
		#endif
	}
	#endif

	if (albedo.a > 0.001) {
		vec3 skyColor = vec3(0.0);
		vec3 newNormal = normal;

		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		vec3 viewPos = ToNDC(screenPos);
		vec3 worldPos = ToWorld(viewPos);

		float NoU = clamp(dot(normal, upVec), -1.0, 1.0);
		float NoL = clamp(dot(normal, lightVec), 0.0, 1.0);
		float NoE = clamp(dot(normal, eastVec), -1.0, 1.0);

		#ifdef VC
		float cloudDepth = texture2D(gaux1, gl_FragCoord.xy / vec2(viewWidth, viewHeight)).a;

		if (cloudDepth > 0.1 && water > 0.9 && cameraPosition.y + VC_STRETCHING * 0.5 > VC_HEIGHT) discard;
		#endif

		vec2 lightmap = clamp(lightMapCoord, 0.0, 1.0);
		if (water > 0.9) albedo *= max(lightmap.y, 0.5);

		#ifdef WATER_NORMALS
		if (water > 0.5) {
			mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
								  tangent.y, binormal.y, normal.y,
								  tangent.z, binormal.z, normal.z);

			float fresnel0 = pow2(clamp(1.0 + dot(newNormal, normalize(viewPos)), 0.0, 1.0));
			newNormal = clamp(normalize(getWaterNormal(worldPos, viewVector, lightmap, fresnel0) * tbnMatrix), vec3(-1.0), vec3(1.0));
		}
		#endif

		getSceneLighting(albedo.rgb, viewPos, worldPos, newNormal, lightmap, NoU, NoL, NoE, emission, 0.0, 0.0, 1.0);

		#if defined OVERWORLD
		skyColor = getAtmosphere(viewPos);
		#elif defined NETHER
		skyColor = netherColSqrt.rgb * 0.25;
		#elif defined END
		skyColor = endLightCol.rgb * 0.15;
		#endif

		#if defined OVERWORLD && defined WATER_FOG
		if (water > 0.9 && rainStrength != 1.0) {
			float oDepth = texture2D(depthtex1, screenPos.xy).r;
			vec3 oScreenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), oDepth);
			vec3 oViewPos = ToNDC(oScreenPos);
			vec3 diffPos = viewPos - oViewPos;

			float DoN = clamp(dot(normalize(diffPos), newNormal), 0.0, 1.0);
			float absorptionFactor = 1.0 - clamp(length(diffPos) * DoN * 0.075, 0.0, 1.0);
				  absorptionFactor *= 1.0 - rainStrength;

			vec3 absorptionColor = albedo.rgb * mix(vec3(1.0), mix(waterColor, vec3(0.0, 1.0, 1.0), absorptionFactor) * 2.0, 1.0 - absorptionFactor * absorptionFactor);

			albedo.rgb = mix(waterColor * 0.5, absorptionColor, absorptionFactor);
			albedo.a = mix(albedo.a, 0.1, absorptionFactor);
		}
		#endif

		#ifdef INTEGRATED_SPECULAR
		if (portal < 0.5) {
			float fresnel1 = pow2(clamp(1.0 + dot(newNormal, normalize(viewPos)), 0.0, 1.0)) * (1.0 - float(isEyeInWater == 1) * 0.75) * (0.3 + water * 0.7);

			getReflection(albedo, viewPos, newNormal, fresnel1, lightmap.y, emission);
		}
		#endif

		Fog(albedo.rgb, viewPos, worldPos, skyColor);
	}

	/* DRAWBUFFERS:014 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = albedo;
	gl_FragData[2] = vec4(1.0);

	#ifdef BLOOM
	/* DRAWBUFFERS:0142 */
	gl_FragData[3].ba = vec2(emission * 0.1, emission);
	#endif
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
#ifdef WATER_NORMALS
out float viewDistance;
#endif

out float mat;
out vec2 texCoord, lightMapCoord;
out vec3 sunVec, upVec, eastVec;
out vec3 normal;

#ifdef WATER_NORMALS
out vec3 viewVector, binormal, tangent;
#endif

out vec4 color;

//Uniforms//
#ifdef TAA
uniform int framemod8;

uniform float viewWidth, viewHeight;
#endif

#ifdef WAVING_WATER
uniform float frameTimeCounter;
#endif

#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

#ifdef WAVING_WATER
uniform vec3 cameraPosition;
#endif

uniform mat4 gbufferModelView, gbufferModelViewInverse;

//Attributes//
attribute vec4 mc_Entity;

#ifdef WATER_NORMALS
attribute vec4 at_tangent;
#endif

#ifdef WAVING_WATER
attribute vec4 mc_midTexCoord;
#endif

//Common Functions//
#ifdef WAVING_WATER
float getWavingWater(vec3 worldPos, float skyLightMap) {
	worldPos += cameraPosition;
	float fractY = fract(worldPos.y + 0.005);
		
	float wave = sin(TAU * (frameTimeCounter * 0.7 + worldPos.x * 0.16 + worldPos.z * 0.08)) +
				 sin(TAU * (frameTimeCounter * 0.5 + worldPos.x * 0.1 + worldPos.z * 0.2));

	if (fractY > 0.01) return wave * 0.075 * skyLightMap;
	
	return 0.0;
}
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

	#ifdef WATER_NORMALS
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
						  tangent.y, binormal.y, normal.y,
						  tangent.z, binormal.z, normal.z);
								  
	viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;
	viewDistance = length(gl_ModelViewMatrix * gl_Vertex);
	#endif

	//Sun & Other vectors
	sunVec = vec3(0.0);

    #if defined OVERWORLD
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * PI) * -0.5 + 0.5 - ang) / 3.0) * TAU;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
    #elif defined END
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
    sunVec = normalize((gbufferModelView * vec4(vec3(0.0, sunRotationData * 2000.0), 1.0)).xyz);
    #endif
	
	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

	//Materials
	mat = 0.0;
	mat = float(mc_Entity.x);

	//Color & Position
    color = gl_Color;

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	
	#ifdef WAVING_WATER
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	if (mc_Entity.x == 1) position.y += getWavingWater(position.xyz, lightMapCoord.y);
	#endif

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

	#ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif