#define GBUFFERS_TERRAIN

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
flat in int mat;
in vec2 texCoord, lightMapCoord;
in vec3 sunVec, upVec, eastVec, northVec;
in vec3 normal;

#if defined INTEGRATED_NORMAL_MAPPING || defined INTEGRATED_NORMAL_MAPPING_INTERNAL
in vec2 signMidCoordPos;
flat in vec2 absMidCoordPos;
#endif

#ifdef PBR
in float dist;
in vec3 viewVector;
in vec4 vTexCoord, vTexCoordAM;
#endif

#if defined INTEGRATED_NORMAL_MAPPING || defined INTEGRATED_NORMAL_MAPPING_INTERNAL || (defined COLORED_LIGHTING || defined GI) || defined PBR
in vec3 binormal, tangent;
#endif

in vec4 color;

//Uniforms//
uniform int frameCounter;
uniform int isEyeInWater;

#ifdef DYNAMIC_HANDLIGHT
uniform int heldItemId, heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
#endif

#ifdef TAA
uniform int framemod8;
#endif

uniform float nightVision;
uniform float frameTimeCounter;
uniform float viewWidth, viewHeight;

#ifdef OVERWORLD
uniform float shadowFade;
uniform float wetness, timeBrightness, timeAngle;
#endif

uniform sampler2D noisetex;

#if defined INTEGRATED_NORMAL_MAPPING || defined INTEGRATED_NORMAL_MAPPING_INTERNAL || defined PBR
uniform ivec2 atlasSize;
#endif

uniform vec3 cameraPosition;

#if defined COLORED_LIGHTING || defined GI
uniform vec3 previousCameraPosition;

uniform ivec2 eyeBrightnessSmooth;
#endif

#ifdef COLORED_LIGHTING
uniform sampler2D gaux1;
#endif

#ifdef GI
uniform sampler2D gaux2;
#endif

#ifdef PBR
uniform sampler2D specular;
uniform sampler2D normals;
#endif

uniform sampler2D texture;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

#if defined COLORED_LIGHTING || defined GI
uniform mat4 gbufferPreviousModelView, gbufferPreviousProjection;
uniform mat4 gbufferProjection;
#endif

#if defined OVERWORLD || defined END
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
#endif

//Common Variables//
const bool gaux1MipmapEnabled = true;
const bool gaux2MipmapEnabled = true;

#ifdef OVERWORLD
float sunVisibility = clamp(dot(sunVec, upVec) + 0.025, 0.0, 0.1) * 10.0;
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
vec3 lightVec = sunVec;
#endif

#ifdef PBR
vec2 dcdx = dFdx(texCoord);
vec2 dcdy = dFdy(texCoord);
#endif

//Includes//
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/encode.glsl"

#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

#if defined OVERWORLD || defined END
#include "/lib/util/ToShadow.glsl"
#include "/lib/lighting/shadows.glsl"
#endif

#ifdef DYNAMIC_HANDLIGHT
#include "/lib/lighting/dynamicHandLight.glsl"
#endif

#if defined INTEGRATED_NORMAL_MAPPING || defined INTEGRATED_NORMAL_MAPPING_INTERNAL
#include "/lib/ipbr/integratedNormalMapping.glsl"
#endif

#if defined INTEGRATED_EMISSION || defined INTEGRATED_EMISSION_INTERNAL
#include "/lib/ipbr/integratedEmissionTerrain.glsl"
#endif

#include "/lib/ipbr/integratedSpecular.glsl"

#include "/lib/color/dimensionColor.glsl"

#if defined COLORED_LIGHTING || defined GI
#include "/lib/util/reprojection.glsl"
#include "/lib/lighting/coloredLightingGbuffers.glsl"
#endif

#ifdef OVERWORLD
#include "/lib/ipbr/ggx.glsl"
#endif

#ifdef PBR
#if defined PARALLAX || defined PARALLAX_INTERNAL || defined SELF_SHADOW
#include "/lib/ipbr/parallax.glsl"
#endif

#include "/lib/ipbr/materialGbuffers.glsl"

#ifdef DIRECTIONAL_LIGHTMAP
#include "/lib/ipbr/directionalLightmap.glsl"
#endif
#endif

#include "/lib/lighting/sceneLighting.glsl"

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * vec4(color.rgb, 1.0);
	vec3 newNormal = normal;

	float leaves = int(mat == 9 || mat == 10);
	float foliage = int(mat == 108 || (mat >= 4 && mat <= 15)) * (1.0 - leaves);
	float subsurface = foliage + leaves;
	float emission = 0.0;
	float smoothness = 0.0;
	float coloredLightingIntensity = 0.0;

	#ifdef PBR
	vec2 newCoord = vTexCoord.st * vTexCoordAM.pq + vTexCoordAM.st;
	float surfaceDepth = 1.0;
	float parallaxFade = clamp((dist - PARALLAX_DISTANCE) / 32.0, 0.0, 1.0);
	
	#if defined PARALLAX || defined PARALLAX_INTERNAL
	if (subsurface < 0.5) newCoord = getParallaxCoord(texCoord, parallaxFade, surfaceDepth);
	albedo = texture2DGradARB(texture, newCoord, dcdx, dcdy) * vec4(color.rgb, 1.0);
	#endif
	#endif

	if (albedo.a > 0.001) {
		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		#ifdef TAA
		vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
		#else
		vec3 viewPos = ToNDC(screenPos);
		#endif
		vec3 worldPos = ToWorld(viewPos);
		vec2 lightmap = clamp(lightMapCoord, 0.0, 1.0);

		#ifdef PBR
		float f0 = 0.0, metalness = 0.0, porosity = 0.5, ao = 1.0;

		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							tangent.y, binormal.y, normal.y,
							tangent.z, binormal.z, normal.z);

		float viewLength = length(viewPos) * 0.01;

		if (viewLength < 1.0) getMaterials(smoothness, metalness, f0, emission, subsurface, porosity, ao, newNormal, newCoord, dcdx, dcdy, tbnMatrix);
		subsurface += foliage + leaves;
		#endif

		#if defined INTEGRATED_NORMAL_MAPPING || defined INTEGRATED_NORMAL_MAPPING_INTERNAL
		getTerrainNormal(newNormal, albedo.rgb, mat);
		#endif

		if (foliage > 0.5) {
			newNormal = upVec * 0.5;
		}

		float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
		float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
		float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

		#if defined INTEGRATED_EMISSION || defined INTEGRATED_EMISSION_INTERNAL
		getIntegratedEmission(albedo, viewPos, worldPos, lightmap, emission, coloredLightingIntensity);
		#endif

		getIntegratedSpecular(albedo, newNormal, worldPos.xz, lightmap, emission, foliage + leaves, smoothness);

		float parallaxShadow = 1.0;
		
		#ifdef PBR
		vec3 rawAlbedo = albedo.rgb * 0.999 + 0.001;
		albedo.rgb *= ao * ao;

		float doParallax = 0.0;

		#if defined SELF_SHADOW || defined SELF_SHADOW_INTERNAL
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

		#ifdef DIRECTIONAL_LIGHTMAP
		mat3 lightmapTBN = GetLightmapTBN(viewPos);
		lightmap.x = getDirectionalLightmap(lightmap.x, lightMapCoord.x, newNormal, lightmapTBN);
		lightmap.y = getDirectionalLightmap(lightmap.y, lightMapCoord.y, newNormal, lightmapTBN);
		#endif
		#endif

		vec3 shadow = vec3(0.0);
		getSceneLighting(albedo.rgb, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, emission, foliage, leaves, subsurface, smoothness, parallaxShadow, coloredLightingIntensity);
	}

	/* DRAWBUFFERS:03 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(EncodeNormal(newNormal), smoothness, coloredLightingIntensity);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
flat out int mat;
out vec2 texCoord, lightMapCoord;
out vec3 sunVec, upVec, eastVec, northVec;
out vec3 normal;

#ifdef PBR
out float dist;
out vec3 viewVector;
out vec4 vTexCoord, vTexCoordAM;
#endif

#if defined INTEGRATED_NORMAL_MAPPING || defined INTEGRATED_NORMAL_MAPPING_INTERNAL || defined PBR
out vec2 signMidCoordPos;
flat out vec2 absMidCoordPos;
#endif

#if defined INTEGRATED_NORMAL_MAPPING || defined INTEGRATED_NORMAL_MAPPING_INTERNAL || (defined COLORED_LIGHTING || defined GI) || defined PBR
out vec3 binormal, tangent;
#endif

out vec4 color;

//Uniforms//
#ifdef TAA
uniform int framemod8;

uniform float viewWidth, viewHeight;
#endif

#ifdef OVERWORLD
uniform float timeAngle;
#endif

#ifdef WAVING_BLOCKS
uniform float frameTimeCounter;

uniform vec3 cameraPosition;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

//Attributes//
attribute vec4 mc_Entity;

#if defined INTEGRATED_NORMAL_MAPPING || defined INTEGRATED_NORMAL_MAPPING_INTERNAL || (defined COLORED_LIGHTING || defined GI) || defined PBR
attribute vec4 at_tangent;
#endif

#if defined WAVING_BLOCKS || defined INTEGRATED_NORMAL_MAPPING || defined INTEGRATED_NORMAL_MAPPING_INTERNAL || defined PBR
attribute vec4 mc_midTexCoord;
#endif

//Includes//
#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

#ifdef WAVING_BLOCKS
#include "/lib/util/waving.glsl"
#endif

//Program//
void main() {
	//Coord
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	lightMapCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lightMapCoord = clamp((lightMapCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	#if defined INTEGRATED_NORMAL_MAPPING || defined INTEGRATED_NORMAL_MAPPING_INTERNAL || defined PBR
	vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
	vec2 texMinMidCoord = texCoord - midCoord;
	signMidCoordPos = sign(texMinMidCoord);
	absMidCoordPos = abs(texMinMidCoord);
	#endif

	//Normal
	normal = normalize(gl_NormalMatrix * gl_Normal);

	#if defined INTEGRATED_NORMAL_MAPPING || defined INTEGRATED_NORMAL_MAPPING_INTERNAL || (defined COLORED_LIGHTING || defined GI) || defined PBR
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent = normalize(gl_NormalMatrix * at_tangent.xyz);

	#ifdef PBR
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
						  tangent.y, binormal.y, normal.y,
						  tangent.z, binormal.z, normal.z);
	
	dist = length(gl_ModelViewMatrix * gl_Vertex);

	viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;

	vTexCoordAM.pq = abs(texMinMidCoord) * 2.0;
	vTexCoordAM.st = min(texCoord, midCoord - texMinMidCoord);
	vTexCoord.xy = sign(texMinMidCoord) * 0.5 + 0.5;
	#endif
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
	northVec = normalize(gbufferModelView[2].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

	//Materials
	mat = int(mc_Entity.x + 0.5);

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	#ifdef WAVING_BLOCKS
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	position.xyz = getWavingBlocks(position.xyz, istopv, lightMapCoord.y);
	#endif

	//Color & Position
    color = gl_Color;
	if (color.a < 0.1) color.a = 1.0;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

	#ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif