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

uniform float viewWidth, viewHeight, far;
uniform float nightVision, blindFactor;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

#ifdef WATER_NORMALS
uniform float frameTimeCounter;
#endif

#ifdef OVERWORLD
uniform float rainStrength;
#endif

#if defined OVERWORLD || defined END
uniform float timeBrightness, timeAngle;
#endif

uniform vec3 cameraPosition;

#ifdef OVERWORLD
uniform ivec2 eyeBrightnessSmooth;

uniform vec3 skyColor, fogColor;

uniform sampler2D depthtex1;
#endif

#ifdef WATER_NORMALS
uniform sampler2D noisetex;
#endif

uniform sampler2D texture;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

#if defined OVERWORLD || defined END
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
#endif

//Common Variables//
#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float ug = mix(clamp((cameraPosition.y - 56.0) / 16.0, 0.0, 1.0), 1.0, eBS);
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

#ifdef OVERWORLD
#include "/lib/util/bayerDithering.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/water/waterFog.glsl"
#endif

#ifdef WATER_NORMALS
#include "/lib/water/waterNormals.glsl"
#endif

#include "/lib/atmosphere/fog.glsl"

#if defined BLOOM || defined INTEGRATED_SPECULAR
#include "/lib/util/encode.glsl"
#endif

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;
	vec3 skyColor = vec3(0.0);
	vec3 newNormal = normal;
	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	vec3 viewPos = ToNDC(screenPos);
	vec3 worldPos = ToWorld(viewPos);

	float water = float(mat > 0.9 && mat < 1.1);
	float portal = float(mat > 1.9 && mat < 2.1);

	albedo.a = mix(albedo.a, 1.0, portal);

	if (water > 0.9) {
		albedo.a = WATER_A;
		albedo.rgb = waterColor;
	}

	if (albedo.a > 0.001) {
		vec2 lightmap = clamp(lightMapCoord, vec2(0.0), vec2(1.0));

		#ifdef WATER_NORMALS
		if (water > 0.5) {
			albedo.rgb = waterColor.rgb;
			albedo.a = WATER_A;

			mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
								 tangent.y, binormal.y, normal.y,
								 tangent.z, binormal.z, normal.z);

			newNormal = clamp(normalize(getWaterNormal(worldPos, viewPos, viewVector, lightmap) * tbnMatrix), vec3(-1.0), vec3(1.0));
		}
		#endif

		getSceneLighting(albedo.rgb, viewPos, worldPos, newNormal, lightmap, portal * pow8(length(albedo.rgb)) * 32.0, 0.0, 0.0);

		#if defined OVERWORLD
		skyColor = getAtmosphere(viewPos);
		#elif defined NETHER
		skyColor = netherColSqrt.rgb * 0.25;
		#elif defined END
		skyColor = endLightCol.rgb * 0.15;
		#endif

		#ifdef OVERWORLD
		if (isEyeInWater == 0 && lightmap.y > 0.0 && water > 0.9) {
			float oDepth = texture2D(depthtex1, screenPos.xy).r;
			vec3 oScreenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), oDepth);
			vec3 oViewPos = ToNDC(oScreenPos);

			vec4 waterFog = getWaterFog(viewPos.xyz - oViewPos) * lightmap.y;
			albedo = mix(waterFog, vec4(albedo.rgb, 0.75), albedo.a);
		}
		#endif

		Fog(albedo.rgb, viewPos, worldPos, skyColor);
	}

	/* DRAWBUFFERS:01 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = albedo;

	#if defined BLOOM || defined INTEGRATED_SPECULAR
	/* DRAWBUFFERS:012 */
	gl_FragData[2] = vec4(EncodeNormal(newNormal), portal * 4.0, 1.0 - portal * 0.75);
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
uniform int frameCounter;

uniform float viewWidth, viewHeight;
#endif

#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

uniform mat4 gbufferModelView;

//Attributes//
attribute vec4 mc_Entity;

#ifdef WATER_NORMALS
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

	//Normals stuff
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
	if (mc_Entity.x == 1.0) mat = 1.0;
	if (mc_Entity.x == 2.0) mat = 2.0;
	if (mc_Entity.x == 3.0) mat = 3.0;

	//Color & Position
    color = gl_Color;

	gl_Position = ftransform();

	#ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif