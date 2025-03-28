#define GBUFFERS_BASIC

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec4 color;
in vec3 normal;
in vec3 eastVec, sunVec, upVec;
in vec2 lmCoord;

//Uniforms//
uniform int isEyeInWater;
uniform int frameCounter;

uniform float viewWidth, viewHeight;
uniform float blindFactor;
uniform float nightVision;
uniform float frameTimeCounter;

#ifdef OVERWORLD
uniform float timeBrightness, timeAngle;
uniform float shadowFade;
uniform float wetness;

uniform ivec2 eyeBrightnessSmooth;
#endif

uniform vec3 cameraPosition;
uniform vec3 skyColor;
uniform vec3 fogColor;

uniform sampler2D noisetex;

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
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/color/netherColor.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/gbuffersLighting.glsl"

//Program//
void main() {
	vec4 albedo = color;
	if (albedo.a <= 0.01) discard;
	vec3 newNormal = normal;

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	vec3 viewPos = ToNDC(screenPos);
	vec3 worldPos = ToWorld(viewPos);
	vec2 lightmap = clamp(lmCoord, 0.0, 1.0);

	float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
	float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
	float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

	vec3 shadow = vec3(0.0);
	gbuffersLighting(albedo, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, 0.0, 0.0, 0.0, 0.0);

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(albedo.rgb * albedo.a, 1.0);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec4 color;
out vec3 normal;
out vec3 eastVec, sunVec, upVec;
out vec2 lmCoord;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;

//Program//
void main() {
	//Lightmap Coord
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Normal
	normal = normalize(gl_NormalMatrix * gl_Normal);

	//Sun & Other vectors
	getSunVector(gbufferModelView, timeAngle, sunVec);
	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

	//Color & Position
	color = gl_Color;

	gl_Position = ftransform();
}

#endif