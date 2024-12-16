#define GBUFFERS_ENTITIES

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
flat in int mat;
in vec2 texCoord;
in vec2 lmCoord;
in vec3 normal;
in vec3 eastVec, northVec, sunVec, upVec;
in vec4 color;

//Uniforms//
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef DYNAMIC_HANDLIGHT
uniform int heldItemId, heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
#endif

#ifdef GENERATED_SPECULAR
uniform int currentRenderedItemId;
#endif

#ifdef AURORA
uniform int moonPhase;
uniform float isSnowy;
#endif

uniform float viewWidth, viewHeight;
uniform float blindFactor;
uniform float nightVision;

#ifdef OVERWORLD
uniform float timeBrightness, timeAngle;
uniform float shadowFade;
uniform float wetness;
#endif

uniform ivec2 eyeBrightnessSmooth;
uniform vec3 cameraPosition;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec4 entityColor;

#ifdef GI
uniform vec3 previousCameraPosition;

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

//Includes//
#include "/lib/util/encode.glsl"
#include "/lib/util/transformMacros.glsl"
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

#if defined GENERATED_EMISSION || defined GENERATED_SPECULAR
#include "/lib/pbr/generatedPBR.glsl"
#endif

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord);
	if (albedo.a < 0.00001) discard;
	albedo *= color;
	albedo.rgb = mix(albedo.rgb, entityColor.rgb * entityColor.rgb * 2.0, entityColor.a);
	vec3 newNormal = normal;

	float emission = 0.0;
	float smoothness = 0.0;
	float metalness = 0.0;
	float subsurface = 0.0;

	float lightningBolt = float(mat == 1);

	if (lightningBolt > 0.5) {
		albedo.rgb = vec3(1.0, 1.2, 1.7) * 0.5;
		albedo.a = 0.75;
	}

	if (lightningBolt < 0.5) {
		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		vec3 viewPos = ToNDC(screenPos);
		vec3 worldPos = ToWorld(viewPos);
		vec2 lightmap = clamp(lmCoord, 0.0, 1.0);

		float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
		float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
		float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

		#if defined GENERATED_EMISSION || defined GENERATED_SPECULAR
		generateIPBR(albedo, worldPos, viewPos, lightmap, emission, smoothness, metalness, subsurface);
		#endif

		vec3 shadow = vec3(0.0);
		gbuffersLighting(albedo, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, subsurface, smoothness, emission, 0.0);
	}

	/* DRAWBUFFERS:03 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(encodeNormal(newNormal), emission * 0.1, 1.0);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
flat out int mat;
out vec2 texCoord;
out vec2 lmCoord;
out vec3 normal;
out vec3 eastVec, northVec, sunVec, upVec;
out vec4 color;

//Uniforms//
uniform int entityId;

#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

uniform mat4 gbufferModelView, gbufferModelViewInverse;

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Lightmap Coord
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Normal
	normal = normalize(gl_NormalMatrix * gl_Normal);

	//Sun & Other vectors
	#if defined OVERWORLD || defined END
	sunVec = getSunVector(gbufferModelView, timeAngle);
	#endif
	
	upVec = normalize(gbufferModelView[1].xyz);
	northVec = normalize(gbufferModelView[2].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

	//Materials
	mat = int(entityId);

	//Color & Position
	color = gl_Color;

	gl_Position = ftransform();
}

#endif