#define GBUFFERS_TERRAIN

#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec4 color;
in vec3 normal, binormal, tangent;
in vec2 texCoord, lmCoord;
flat in int mat;

#if defined GENERATED_NORMALS || defined PARALLAX || defined PBR || defined RAIN_PUDDLES
in float dist;
flat in vec2 absMidCoordPos;
in vec2 signMidCoordPos;
in vec3 viewVector;
in vec4 vTexCoord, vTexCoordAM;
#endif

// Uniforms //
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef AURORA_LIGHTING_INFLUENCE
uniform int moonPhase;
#endif

uniform int worldDay, worldTime;

uniform float frameTimeCounter;
uniform float far, near;
uniform float viewWidth, viewHeight;
uniform float blindFactor, nightVision;
#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

#ifdef OVERWORLD
uniform float wetness;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;

#if MC_VERSION >= 12104
uniform float isPaleGarden;
#endif

uniform vec3 skyColor;
#endif

#ifdef GENERATED_NORMALS
uniform ivec2 atlasSize;
#endif

uniform ivec2 eyeBrightnessSmooth;
uniform vec3 cameraPosition;

#ifdef NETHER
uniform vec3 fogColor;
#endif

uniform vec4 lightningBoltPosition;

uniform sampler2D texture, noisetex;
#ifdef PBR
uniform sampler2D specular;
uniform sampler2D normals;
#endif

#ifdef VX_SUPPORT
uniform sampler3D floodfillSampler, floodfillSamplerCopy;
uniform usampler3D voxelSampler;
#endif

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

// Global Variables //
#if defined OVERWORLD
const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
float fractTimeAngle = fract(timeAngle - 0.25);
float ang = (fractTimeAngle + (cos(fractTimeAngle * 3.14159265358979) * -0.5 + 0.5 - fractTimeAngle) / 3.0) * 6.28318530717959;
vec3 sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
#elif defined END
const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
vec3 sunVec = normalize((gbufferModelView * vec4(1.0, sunRotationData * 2000.0, 1.0)).xyz);
#else
vec3 sunVec = vec3(0.0);
#endif

vec3 upVec = normalize(gbufferModelView[1].xyz);
vec3 eastVec = normalize(gbufferModelView[0].xyz);

#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = fmix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, sqrt(eBS));
float sunVisibility = clamp((dot( sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#endif

vec2 dcdx = dFdx(texCoord);
vec2 dcdy = dFdy(texCoord);

// Includes //
#include "/lib/util/encode.glsl"
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/transformMacros.glsl"
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/color/lightColor.glsl"

#ifndef NETHER
#include "/lib/pbr/ggx.glsl"
#endif

#if defined VX_SUPPORT || defined DYNAMIC_HANDLIGHT
#include "/lib/vx/blocklightColor.glsl"
#endif

#ifdef VX_SUPPORT
#include "/lib/vx/voxelization.glsl"
#endif

#include "/lib/lighting/lightning.glsl"
#include "/lib/lighting/shadows.glsl"

#ifdef VC_SHADOWS
#include "/lib/lighting/cloudShadows.glsl"
#endif

#ifdef DYNAMIC_HANDLIGHT
#include "/lib/lighting/handlight.glsl"
#endif

#include "/lib/lighting/gbuffersLighting.glsl"

#if defined GENERATED_EMISSION || defined GENERATED_SPECULAR
#include "/lib/pbr/generatedPBR.glsl"
#endif

#ifdef GENERATED_NORMALS
#include "/lib/pbr/generatedNormals.glsl"
#endif

#ifdef PBR
#if defined PARALLAX || defined SELF_SHADOW
#include "/lib/pbr/parallax.glsl"
#endif

#include "/lib/pbr/materialGbuffers.glsl"
#endif

#if defined RAIN_PUDDLES && (defined GENERATED_SPECULAR || defined PBR)
#include "/lib/pbr/rainPuddles.glsl"
#endif

// Main //
void main() {
	vec4 albedoTexture = texture2D(texture, texCoord);
	vec4 albedo = albedoTexture;
 
	#ifndef GBUFFERS_TERRAIN_COLORWHEEL
    	albedo *= color;
		vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));
	#else
		float ao;
		vec2 lmCoordColorwheel;
		vec4 overlayColor;

		clrwl_computeFragment(albedoTexture, albedo, lmCoordColorwheel, ao, overlayColor);
		albedo.rgb = fmix(albedo.rgb, overlayColor.rgb, overlayColor.a);
		vec2 lightmap = clamp((lmCoordColorwheel - 1.0 / 32.0) * 32.0 / 30.0, vec2(0.0), vec2(1.0));
	#endif

    vec3 newNormal = normal;
    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    vec3 viewPos = ToNDC(screenPos);
    vec3 worldPos = ToWorld(viewPos);

	float leaves = float(mat == 10314);
	float saplings = float(mat == 10317);
	float foliage = float(mat >= 10304 && mat <= 10319 || mat >= 10035 && mat <= 10040) * (1.0 - leaves) * (1.0 - saplings);
	float subsurface = leaves * 2.5 + foliage * 0.6 + saplings * 0.4;
    float emission = 0.0, smoothness = 0.0, metalness = 0.0, porosity = 0.5, parallaxShadow = 0.0;

	#if defined GENERATED_NORMALS || defined PARALLAX || defined PBR || defined RAIN_PUDDLES
	vec2 newCoord = vTexCoord.st * vTexCoordAM.pq + vTexCoordAM.st;
	#endif

	#ifdef PBR
	float surfaceDepth = 1.0;
	float parallaxFade = clamp((dist - PARALLAX_DISTANCE) / 32.0, 0.0, 1.0);
	
	#ifdef PARALLAX
	newCoord = getParallaxCoord(texCoord, parallaxFade, surfaceDepth);
	albedo = texture2DGradARB(texture, newCoord, dcdx, dcdy) * vec4(color.rgb, 1.0);
	#endif
	#endif

	#ifdef PBR
	float f0 = 0.0, ao = 1.0;

	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
						tangent.y, binormal.y, normal.y,
						tangent.z, binormal.z, normal.z);

	float viewLength = length(viewPos) * 0.01;

	getMaterials(smoothness, metalness, f0, emission, subsurface, porosity, ao, newNormal, newCoord, dcdx, dcdy, tbnMatrix);
	#endif

	#ifdef GENERATED_NORMALS
    if (subsurface < 0.1) generateNormals(newNormal, albedoTexture.rgb, viewPos, mat);
	#endif

	#ifdef OVERWORLD
	if (foliage > 0.5) {
		float foliageNormalDistance = min(1.0, length(viewPos.xz) / shadowDistance);
		newNormal = normalize(upVec) * (1.0 - foliageNormalDistance * 0.4 * timeBrightness);
	}
	#endif

	float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
    #if defined OVERWORLD
	float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
    #elif defined END
    float NoL = clamp(dot(newNormal, sunVec), 0.0, 1.0);
    #else
    float NoL = 0.0;
    #endif
	float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

	#if defined GENERATED_EMISSION || defined GENERATED_SPECULAR
	generateIPBR(albedo, worldPos, viewPos, lightmap, NoU, emission, smoothness, metalness, subsurface);
	#endif

	#if defined RAIN_PUDDLES && (defined GENERATED_SPECULAR || defined PBR)
	if (emission < 0.01 && foliage < 0.1 && isSnowy < 0.1) {
		float puddles = GetPuddles(worldPos, newCoord, lmCoord.y, NoU, wetness * (1.0 - isSnowy));

		ApplyPuddleToMaterial(puddles, albedo, smoothness, metalness, porosity);

		if (puddles > 0.001 && wetness > 0.001) {
			mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
								  tangent.y, binormal.y, normal.y,
								  tangent.z, binormal.z, normal.z);

			vec3 puddleNormal = GetPuddleNormal(worldPos, viewPos, tbnMatrix);
			newNormal = normalize(
				fmix(newNormal, puddleNormal, puddles * sqrt(1.0 - porosity) * wetness)
			);
		}
	}
	#endif

	#ifdef PBR
	vec3 rawAlbedo = albedo.rgb * 0.999 + 0.001;
	albedo.rgb *= ao * ao;
	albedo.rgb *= 1.0 - metalness * smoothness * 0.5;

	float doParallax = 0.0;

	#ifdef SELF_SHADOW
	#ifdef OVERWORLD
    float pNoL = dot(newNormal, lightVec);
	doParallax = float(lightmap.y > 0.0 && pNoL > 0.0);
	#endif

	#ifdef END
    float pNoL = dot(newNormal, sunVec);
	doParallax = float(pNoL > 0.0);
	#endif
	
	if (doParallax > 0.5 && viewLength < 1.0) {
        #ifdef OVERWORLD
		parallaxShadow = getParallaxShadow(surfaceDepth, parallaxFade, newCoord, lightVec, tbnMatrix);
        #else
        parallaxShadow = getParallaxShadow(surfaceDepth, parallaxFade, newCoord, sunVec, tbnMatrix);
        #endif
	} else {
		parallaxShadow = 1.0;
	}
	#endif

    //float normalFresnel = pow2(clamp(1.0 + dot(newNormal, normalize(viewPos)), 0.0, 1.0));
	#endif

    vec3 shadow = vec3(0.0);
    gbuffersLighting(color, albedo, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, subsurface, emission, smoothness, parallaxShadow);

	/* DRAWBUFFERS:03 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(encodeNormal(newNormal), lightmap.y * 0.5, clamp(fmix(smoothness, 1.0, metalness * metalness), 0.0, 0.95));
}

#endif


//**//**//**//**//**//**//**//**//**//**//**//**//**//**//


#ifdef VSH

// VSH Data //
out vec4 color;
out vec3 normal, binormal, tangent;
out vec2 texCoord, lmCoord;
flat out int mat;

#if defined GENERATED_NORMALS || defined PARALLAX || defined PBR || defined RAIN_PUDDLES
out float dist;
flat out vec2 absMidCoordPos;
out vec2 signMidCoordPos;
out vec3 viewVector;
out vec4 vTexCoord, vTexCoordAM;
#endif

// Uniforms //
#ifdef TAA
uniform float viewWidth, viewHeight;
#endif

#if defined WAVING_LEAVES || defined WAVING_PLANTS
uniform float frameTimeCounter;

uniform vec3 cameraPosition;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

// Attributes //
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;
attribute vec4 at_tangent;

// Includes //
#ifdef TAA
#include "/lib/antialiasing/jitter.glsl"
#endif

#if defined WAVING_LEAVES || defined WAVING_PLANTS
#include "/lib/pbr/waving.glsl"
#endif

// Main //
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));
	
    color = gl_Color;

	//Normal, Binormal and Tangent
	normal = normalize(gl_NormalMatrix * gl_Normal);
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent = normalize(gl_NormalMatrix * at_tangent.xyz);

	#if defined GENERATED_NORMALS || defined PARALLAX || defined PBR || defined RAIN_PUDDLES
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

    mat = int(mc_Entity.x + 0.5);

	//Position
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	#if defined WAVING_PLANTS || defined WAVING_LEAVES
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	position.xyz = getWavingBlocks(position.xyz, istopv, lmCoord.y);
	#endif

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

	//TAA jittering
    #ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
    #endif
}

#endif