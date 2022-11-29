//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_HAND

#ifdef FSH

//Varyings//
in vec2 texCoord, lightMapCoord;
in vec3 sunVec, upVec, eastVec;
in vec3 normal;
in vec4 color;

//Uniforms//
#ifdef DYNAMIC_HANDLIGHT
uniform int heldItemId, heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
#endif

uniform float viewWidth, viewHeight;
uniform float nightVision;
uniform float frameTimeCounter;

#ifdef OVERWORLD
uniform float rainStrength;
uniform float shadowFade;
#endif

#if defined OVERWORLD || defined END
uniform float timeBrightness, timeAngle;
#endif

uniform vec3 cameraPosition;

#if defined BLOOM_COLORED_LIGHTING || defined GLOBAL_ILLUMINATION
uniform sampler2D gaux1;
#endif

uniform sampler2D texture;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

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

#ifdef OVERWORLD
float sunVisibility = clamp(dot(sunVec, upVec) + 0.025, 0.0, 0.1) * 10.0;
#endif

//Includes//
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/bayerDithering.glsl"

#if defined OVERWORLD || defined END
#include "/lib/util/ToShadow.glsl"
#include "/lib/lighting/shadows.glsl"
#endif

#ifdef SHIMMER_MOD_SUPPORT
#include "/lib/lighting/shimmerModSupport.glsl"
#endif

#include "/lib/color/dimensionColor.glsl"
#include "/lib/lighting/sceneLighting.glsl"

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;

	if (albedo.a > 0.001) {
		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z + 0.38);
		vec3 viewPos = ToNDC(screenPos);
		vec3 worldPos = ToWorld(viewPos);
		vec2 lightmap = clamp(lightMapCoord, 0.0, 1.0);

		float NoU = clamp(dot(normal, upVec), -1.0, 1.0);
		float NoL = clamp(dot(normal, lightVec), 0.0, 1.0);
		float NoE = clamp(dot(normal, eastVec), -1.0, 1.0);

		getSceneLighting(albedo.rgb, screenPos, viewPos, worldPos, normal, lightmap, NoU, NoL, NoE, 0.0, 0.0, 0.0, 0.0);
	}

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord, lightMapCoord;
out vec3 sunVec, upVec, eastVec;
out vec3 normal;
out vec4 color;

//Uniforms//
#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

uniform mat4 gbufferModelView;

//Program//
void main() {
	//Coord
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	lightMapCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lightMapCoord = clamp(lightMapCoord, vec2(0.0), vec2(0.9333, 1.0));

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

	//Color & Position
    color = gl_Color;

	gl_Position = ftransform();
}

#endif