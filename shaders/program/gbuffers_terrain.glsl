#define GBUFFERS_TERRAIN

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
flat in int mat;
in vec2 texCoord, lmCoord;
in vec3 normal, binormal, tangent;
in vec3 eastVec, northVec, sunVec, upVec;
in vec4 color;

#if defined GENERATED_NORMALS || defined PARALLAX || defined SELF_SHADOW || defined PBR
in float dist;
flat in vec2 absMidCoordPos;
in vec2 signMidCoordPos;
in vec3 viewVector;
in vec4 vTexCoord, vTexCoordAM;
#endif

//Uniforms//
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef DYNAMIC_HANDLIGHT
uniform int heldItemId, heldItemId2;
#endif

#ifdef AURORA
uniform int moonPhase;
uniform float isSnowy;
#endif

uniform float frameTimeCounter;
uniform float viewWidth, viewHeight;
uniform float blindFactor;
uniform float nightVision;

#ifdef OVERWORLD
uniform float timeBrightness, timeAngle;
uniform float shadowFade;
uniform float wetness, rainStrength;
#endif

uniform ivec2 eyeBrightnessSmooth;
uniform ivec2 atlasSize;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec3 cameraPosition;

#ifdef GI
uniform vec3 previousCameraPosition;
#endif

#ifdef PBR
uniform sampler2D specular;
uniform sampler2D normals;
#endif

#ifdef GI
uniform sampler2D gaux1;
#endif

uniform sampler2D texture;
uniform sampler2D noisetex;

uniform sampler3D floodfillSampler;
uniform usampler3D voxelSampler;

#ifdef GI
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
#endif

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

//Common Variables//
#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
vec3 lightVec = sunVec;
#endif

vec2 dcdx = dFdx(texCoord);
vec2 dcdy = dFdy(texCoord);

//Includes//
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/transformMacros.glsl"
#include "/lib/util/encode.glsl"
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/color/netherColor.glsl"
#include "/lib/vx/blocklightColor.glsl"
#include "/lib/vx/voxelization.glsl"
#include "/lib/pbr/ggx.glsl"
#include "/lib/lighting/shadows.glsl"

#ifdef GI
#include "/lib/util/reprojection.glsl"
#endif

#include "/lib/lighting/gbuffersLighting.glsl"

#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

#ifdef PBR
#if defined PARALLAX || defined SELF_SHADOW
#include "/lib/pbr/parallax.glsl"
#endif

#include "/lib/pbr/materialGbuffers.glsl"
#endif

#ifdef RAIN_PUDDLES
#include "/lib/pbr/rainPuddles.glsl"
#endif

#if defined GENERATED_EMISSION || defined GENERATED_SPECULAR
#include "/lib/pbr/generatedPBR.glsl"
#endif

#ifdef GENERATED_NORMALS
#include "/lib/pbr/generatedNormals.glsl"
#endif

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord);
	if (albedo.a <= 0.00001) discard;
	vec4 albedoP = albedo;
	albedo *= color;

	vec3 newNormal = normal;

	float leaves = float(mat == 10314);
	float foliage2 = float(mat == 10317);
	float foliage = float(mat >= 10304 && mat <= 10319 || mat >= 35 && mat <= 40) * (1.0 - leaves) * (1.0 - foliage2);
	float subsurface = foliage + leaves * 0.5 + foliage2 * 0.3;
    float smoothness = 0.0, metalness = 0.0;
	float emission = 0.0, porosity = 0.5;

	vec2 newCoord = vTexCoord.st * vTexCoordAM.pq + vTexCoordAM.st;

	#ifdef PBR
	float surfaceDepth = 1.0;
	float parallaxFade = clamp((dist - PARALLAX_DISTANCE) / 32.0, 0.0, 1.0);
	
	#if defined PARALLAX
	newCoord = getParallaxCoord(texCoord, parallaxFade, surfaceDepth);
	albedo = texture2DGradARB(texture, newCoord, dcdx, dcdy) * vec4(color.rgb, 1.0);
	#endif
	#endif

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	#ifdef TAA
	vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
	#else
	vec3 viewPos = ToNDC(screenPos);
	#endif
	vec3 worldPos = ToWorld(viewPos);
	vec2 lightmap = clamp(lmCoord, 0.0, 1.0);

	#ifdef PBR
	float f0 = 0.0, ao = 1.0;

	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
						tangent.y, binormal.y, normal.y,
						tangent.z, binormal.z, normal.z);

	float viewLength = length(viewPos) * 0.01;

	getMaterials(smoothness, metalness, f0, emission, subsurface, porosity, ao, newNormal, newCoord, dcdx, dcdy, tbnMatrix);
	#endif

	#ifdef GENERATED_NORMALS
	generateNormals(newNormal, albedo.rgb, viewPos, mat);
	#endif

	if (foliage > 0.5) {
		newNormal = upVec;
	}

	float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
	float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
	float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

	#if defined GENERATED_EMISSION || defined GENERATED_SPECULAR
	generateIPBR(albedo, worldPos, viewPos, lightmap, emission, smoothness, metalness, subsurface);
	#endif

	#ifdef RAIN_PUDDLES
	if (emission < 0.01 && foliage < 0.1) {
		float puddlesNoU = dot(newNormal, upVec);

		float puddles = GetPuddles(worldPos, newCoord, lmCoord.y, puddlesNoU, wetness);

		ApplyPuddleToMaterial(puddles, albedo, smoothness, metalness, porosity);

		if (puddles > 0.001 && rainStrength > 0.001) {
			mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
								  tangent.y, binormal.y, normal.y,
								  tangent.z, binormal.z, normal.z);

			vec3 puddleNormal = GetPuddleNormal(worldPos, viewPos, tbnMatrix);
			newNormal = normalize(
				mix(newNormal, puddleNormal, puddles * sqrt(1.0 - porosity) * rainStrength)
			);
		}
	}
	#endif

	float parallaxShadow = 1.0;
	
	#ifdef PBR
	vec3 rawAlbedo = albedo.rgb * 0.999 + 0.001;
	albedo.rgb *= ao * ao;
	albedo.rgb *= 1.0 - metalness * smoothness * 0.5;

	float doParallax = 0.0;

	#ifdef SELF_SHADOW
	float pNoL = dot(newNormal, lightVec);

	#ifdef OVERWORLD
	doParallax = float(lightmap.y > 0.0 && pNoL > 0.0);
	#endif

	#ifdef END
	doParallax = float(pNoL > 0.0);
	#endif
	
	if (doParallax > 0.5 && viewLength < 1.0) {
		parallaxShadow = getParallaxShadow(surfaceDepth, parallaxFade, newCoord, lightVec, tbnMatrix);
	}
	#endif
	#endif

	vec3 shadow = vec3(0.0);
	gbuffersLighting(albedo, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, subsurface, smoothness, emission, parallaxShadow);

	/* DRAWBUFFERS:03 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(encodeNormal(newNormal), emission * 0.1, clamp(mix(smoothness, 1.0, metalness), 0.0, 0.95));
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
flat out int mat;
out vec2 texCoord, lmCoord;
out vec3 normal, binormal, tangent;
out vec3 eastVec, northVec, sunVec, upVec;
out vec4 color;

#if defined GENERATED_NORMALS || defined PARALLAX || defined SELF_SHADOW || defined PBR
out float dist;
flat out vec2 absMidCoordPos;
out vec2 signMidCoordPos;
out vec3 viewVector;
out vec4 vTexCoord, vTexCoordAM;
#endif

//Uniforms//
#ifdef TAA
uniform float viewWidth, viewHeight;
#endif

#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

#if defined WAVING_LEAVES || defined WAVING_PLANTS
uniform float frameTimeCounter;
uniform float rainStrength;

uniform vec3 cameraPosition;
#endif

uniform mat4 gbufferModelView, gbufferModelViewInverse;

//Attributes//
attribute vec4 at_tangent;
attribute vec4 at_midBlock;
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

//Includes
#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

#if defined WAVING_LEAVES || defined WAVING_PLANTS
#include "/lib/util/waving.glsl"
#endif

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Normal, Binormal and Tangent
	normal = normalize(gl_NormalMatrix * gl_Normal);
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent = normalize(gl_NormalMatrix * at_tangent.xyz);

	#if defined GENERATED_NORMALS || defined PARALLAX || defined SELF_SHADOW || defined PBR
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
						  tangent.y, binormal.y, normal.y,
						  tangent.z, binormal.z, normal.z);
	
	dist = length(gl_ModelViewMatrix * gl_Vertex);
	viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;

	vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
	vec2 texMinMidCoord = texCoord - midCoord;
	signMidCoordPos = sign(texMinMidCoord);
	absMidCoordPos = abs(texMinMidCoord);
	vTexCoordAM.pq = abs(texMinMidCoord) * 2.0;
	vTexCoordAM.st = min(texCoord, midCoord - texMinMidCoord);
	vTexCoord.xy = sign(texMinMidCoord) * 0.5 + 0.5;
	#endif

	//Sun & Other vectors
	#if defined OVERWORLD || defined END
	sunVec = getSunVector(gbufferModelView, timeAngle);
	#endif

	upVec = normalize(gbufferModelView[1].xyz);
	northVec = normalize(gbufferModelView[2].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

	//Materials
	mat = int(mc_Entity.x + 0.5);

	//Color & Position
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	#if defined WAVING_PLANTS || defined WAVING_LEAVES
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	position.xyz = getWavingBlocks(position.xyz, istopv, lmCoord.y);
	#endif

	color = gl_Color;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

	#ifdef TAA
	if (!(mat >= 10035 && mat <= 10040)) gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif

	#ifndef DRM_S0L4S
	texCoord.x = texCoord.y;
	#endif
}

#endif