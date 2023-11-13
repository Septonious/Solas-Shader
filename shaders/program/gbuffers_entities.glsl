#define GBUFFERS_ENTITIES

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
flat in int mat;
in vec2 texCoord;
in vec2 lmCoord;
in vec3 normal;
in vec3 sunVec, upVec, eastVec;
in vec4 color;

//Uniforms//
uniform int frameCounter;
uniform int isEyeInWater;

#ifdef DYNAMIC_HANDLIGHT
uniform int heldItemId, heldItemId2;
uniform int heldBlockLightValue, heldBlockLightValue2;
#endif

uniform float nightVision;
uniform float frameTimeCounter;
uniform float viewWidth, viewHeight;

#ifdef OVERWORLD
uniform float shadowFade;
uniform float wetness, timeBrightness, timeAngle;
#endif

uniform vec3 cameraPosition;
uniform vec4 entityColor;

#if defined COLORED_LIGHTING || defined GI
uniform vec3 previousCameraPosition;
#endif

#ifdef COLORED_LIGHTING
uniform sampler2D gaux1;
#endif

#ifdef GI
uniform sampler2D gaux2;
#endif

uniform sampler2D texture;
uniform sampler2D noisetex;

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

//Variables//
#ifdef OVERWORLD
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
float sunVisibility = clamp(dot(sunVec, upVec) + 0.025, 0.0, 0.1) * 10.0;
#else
vec3 lightVec = sunVec;
#endif

//Includes//
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/encode.glsl"

#if defined OVERWORLD || defined END
#include "/lib/util/ToShadow.glsl"
#include "/lib/lighting/shadows.glsl"
#endif

#ifdef DYNAMIC_HANDLIGHT
#include "/lib/lighting/dynamicHandLight.glsl"
#endif

#if defined COLORED_LIGHTING || defined GI
#include "/lib/util/reprojection.glsl"
#include "/lib/lighting/coloredLightingGbuffers.glsl"
#endif

#include "/lib/color/dimensionColor.glsl"
#include "/lib/lighting/sceneLighting.glsl"

#ifdef INTEGRATED_EMISSION
#include "/lib/ipbr/integratedEmissionEntities.glsl"
#endif

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;
		 albedo.rgb = mix(albedo.rgb, entityColor.rgb * entityColor.rgb * 2.0, entityColor.a);
	vec3 newNormal = normal;

	float emission = 0.0;

	#ifdef TEST01
	float test = float(mat == 0);
	if (test > 0.5) {
		albedo.rgb *= 2.0;
		albedo.a = 0.25;
	}
	#endif

	float lightningBolt = float(mat == 1);

	if (lightningBolt > 0.5) {
		albedo.rgb = vec3(1.0, 1.2, 1.7) * 0.5;
		albedo.a = 0.75;
	}

	if (albedo.a > 0.001 && lightningBolt < 0.5) {
		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		vec3 viewPos = ToNDC(screenPos);
		vec3 worldPos = ToWorld(viewPos);

		vec2 lightmap = clamp(lmCoord, 0.0, 1.0);

		float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
		float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
		float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

		#ifdef INTEGRATED_EMISSION
		getIntegratedEmission(albedo.rgb, lightmap, emission);
		#endif

		vec3 shadow = vec3(0.0);
		getSceneLighting(albedo.rgb, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, emission, 0.0, 0.0);
	}

	/* DRAWBUFFERS:03 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(EncodeNormal(normal), 0.0, 1.0);
}

#endif


/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
flat out int mat;
out vec2 texCoord;
out vec2 lmCoord;
out vec3 normal;
out vec3 sunVec, upVec, eastVec;
out vec4 color;

//Uniforms//
uniform int entityId;

#ifdef OVERWORLD
uniform float timeAngle;
#endif

uniform mat4 gbufferModelView;

//Program//
void main() {
	//Coord
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Normal
	normal = normalize(gl_NormalMatrix * gl_Normal);

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
	mat = int(entityId);

	//Color & Position
    color = gl_Color;

	gl_Position = ftransform();
}

#endif