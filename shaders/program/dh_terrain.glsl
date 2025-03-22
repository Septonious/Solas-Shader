#define DH_TERRAIN
#define GBUFFERS_TERRAIN

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec4 color;
in vec3 eastVec, sunVec, upVec;
in vec3 normal, binormal, tangent;
in vec2 texCoord, lmCoord;
flat in int mat;

//Uniforms//
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef VC_SHADOWS
uniform int worldDay, worldTime;
#endif

uniform float far, near;
uniform float viewWidth, viewHeight;
uniform float blindFactor;
uniform float nightVision;
uniform float frameTimeCounter;

#ifdef OVERWORLD
uniform float timeBrightness, timeAngle;
uniform float shadowFade;
uniform float wetness;

#ifdef AURORA
uniform int moonPhase;
uniform float isSnowy;
#endif

uniform ivec2 eyeBrightnessSmooth;
#endif

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec3 cameraPosition;

uniform sampler2D noisetex;

uniform mat4 dhProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

//Common Variables//
mat4 gbufferProjectionInverse = dhProjectionInverse;

#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
vec3 lightVec = sunVec;
#endif

//From BSL
float getLuminance(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float getBlueNoise3D(vec3 pos, vec3 normal) {
	pos = (floor(pos + 0.01) + 0.5) / 512.0;

	vec3 worldNormal = (gbufferModelViewInverse * vec4(normal, 0.0)).xyz;
	vec3 noise3D = vec3(
		texture2D(noisetex, pos.yz).b,
		texture2D(noisetex, pos.xz).b,
		texture2D(noisetex, pos.xy).b
	);

	float noiseX = noise3D.x * abs(worldNormal.x);
	float noiseY = noise3D.y * abs(worldNormal.y);
	float noiseZ = noise3D.z * abs(worldNormal.z);
	float noise = noiseX + noiseY + noiseZ;

	return noise - 0.25;
}

//Includes//
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/encode.glsl"
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/color/netherColor.glsl"

#ifndef NETHER
#include "/lib/pbr/ggx.glsl"
#endif

#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/gbuffersLighting.glsl"

#ifdef TAA
#include "/lib/antialiasing/jitter.glsl"
#endif

//Program//
void main() {
	vec4 albedo = color;
	vec4 albedoP = albedo;

	vec3 newNormal = normal;

	float leaves = 0.0;
	float foliage2 = 0.0;
	float foliage = 0.0;
    float smoothness = 0.0, metalness = 0.0, emission = 0.0, porosity = 0.5, subsurface = 0.0;
	float parallaxShadow = 0.0;

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	#ifdef TAA
	vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
	#else
	vec3 viewPos = ToNDC(screenPos);
	#endif
	vec3 worldPos = ToWorld(viewPos);
	vec2 lightmap = clamp(lmCoord, 0.0, 1.0);

	float dither = Bayer8(gl_FragCoord.xy);
	float viewLength = length(viewPos);
	float minDist = (dither - 1.0) * 16.0 + far;
	if (viewLength < minDist) {
		discard;
	}

	vec3 noisePos = (worldPos + cameraPosition) * 4.0;
	float albedoLuma = getLuminance(albedo.rgb);
	float noiseAmount = (1.0 - albedoLuma * albedoLuma) * 0.125;
	float albedoNoise = getBlueNoise3D(noisePos, normal);
	albedo.rgb = clamp(albedo.rgb + albedoNoise * noiseAmount, vec3(0.0), vec3(1.0));

	if (foliage > 0.5) {
		newNormal = upVec;
	}

	float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
	float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
	float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

	vec3 shadow = vec3(0.0);
	gbuffersLighting(albedo, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, subsurface, smoothness, emission, parallaxShadow);

	/* DRAWBUFFERS:03 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(encodeNormal(newNormal), 0.0, 1.0);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec4 color;
out vec3 eastVec, sunVec, upVec;
out vec3 normal, binormal, tangent;
out vec2 texCoord, lmCoord;
flat out int mat;

//Uniforms//
#ifdef TAA
uniform float viewWidth, viewHeight;
#endif

#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

uniform mat4 gbufferModelView, gbufferModelViewInverse;

//Attributes//
attribute vec4 at_tangent;
attribute vec4 at_midBlock;
attribute vec4 mc_midTexCoord;

//Includes//
#ifdef TAA
#include "/lib/antialiasing/jitter.glsl"
#endif

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Lightmap Coord
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Normal, Binormal and Tangent
	normal = normalize(gl_NormalMatrix * gl_Normal);
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent = normalize(gl_NormalMatrix * at_tangent.xyz);

	//Sun & Other vectors
	#if defined OVERWORLD || defined END
	sunVec = getSunVector(gbufferModelView, timeAngle);
	#endif

	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

	//Materials
	mat = 0;

	//Color & Position
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	color = gl_Color;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

    #ifdef TAA
    gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
    #endif

	#ifndef DRM_S0L4S
	texCoord.x = texCoord.y;
	#endif
}

#endif