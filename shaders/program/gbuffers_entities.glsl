//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_ENTITIES

#ifdef FSH

//Varyings//
in float mat;
in vec2 texCoord, lightMapCoord;
in vec3 sunVec, upVec, eastVec;
in vec3 normal;
in vec4 color;

//Uniforms//
uniform int entityId;

uniform float viewWidth, viewHeight;
uniform float nightVision;
uniform float frameTimeCounter;

#ifdef OVERWORLD
uniform float rainStrength;
#endif

#if defined OVERWORLD || defined END
uniform float timeBrightness, timeAngle;
#endif

uniform vec3 cameraPosition;

uniform vec4 entityColor;

uniform sampler2D texture;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

#if defined OVERWORLD || defined END
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
#endif

//Common Variables//
#ifdef OVERWORLD
float sunVisibility = clamp((dot(sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
#endif

//Includes//
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/bayerDithering.glsl"

#if defined OVERWORLD || defined END
#include "/lib/util/ToShadow.glsl"
#include "/lib/lighting/shadows.glsl"
#endif

#include "/lib/color/dimensionColor.glsl"
#include "/lib/lighting/sceneLighting.glsl"

#ifdef INTEGRATED_EMISSION
#include "/lib/ipbr/integratedEmissionEntities.glsl"
#endif

#if defined BLOOM || defined INTEGRATED_SPECULAR
#include "/lib/util/encode.glsl"
#endif

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;
		 albedo.a *= 1.0 - float(color.a >= 0.24 && color.a < 0.255);
		 albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

	float lightningBolt = float(entityId == 0);
	float nametagText = float(length(entityColor.rgb) > 0.0);
	float emission = float(entityColor.a > 0.05) * 0.025 + lightningBolt;

	if (lightningBolt > 0.5) {
		albedo.rgb = vec3(1.0);
		albedo.rgb *= albedo.rgb * albedo.rgb;
		albedo.a = 1.0;
	}

	if (nametagText < 0.5) {
		albedo.rgb *= albedo.rgb;
		emission = 0.125;
	}

	#ifndef ENTITY_HIGHLIGHT
	if (albedo.a > 0.001 && lightningBolt < 0.5 && nametagText > 0.5) {
		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		vec3 viewPos = ToNDC(screenPos);
		vec3 worldPos = ToWorld(viewPos);
		vec2 lightmap = clamp(lightMapCoord, 0.0, 1.0);

		#ifdef INTEGRATED_EMISSION
		getIntegratedEmission(albedo.rgb, lightmap, emission);
		#endif

		getSceneLighting(albedo.rgb, viewPos, worldPos, normal, lightmap, emission, 0.0, 0.0, 0.0);
	}
	#endif
	
	/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;

	#ifndef INTEGRATED_SPECULAR
		#ifdef BLOOM
		/* DRAWBUFFERS:02 */
		gl_FragData[1] = vec4(EncodeNormal(normal), emission * 0.01, 1.0);
		#endif
	#else
		/* DRAWBUFFERS:062 */
		gl_FragData[1] = vec4(albedo.rgb, 1.0);
		gl_FragData[2] = vec4(EncodeNormal(normal), emission * 0.01, 1.0);
	#endif
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out float mat;
out vec2 texCoord, lightMapCoord;
out vec3 sunVec, upVec, eastVec;
out vec3 normal;
out vec4 color;

//Uniforms//
#ifdef INTEGRATED_EMISSION
uniform int entityId;
#endif

#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

uniform mat4 gbufferModelView;

//Includes//
#ifdef INTEGRATED_EMISSION
#include "/lib/ipbr/integratedEmissionEntities.glsl"
#endif

//Program//
void main() {
	//Coord
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	lightMapCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lightMapCoord = clamp((lightMapCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Normal
	normal = normalize(gl_NormalMatrix * gl_Normal);

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
	
	#ifdef INTEGRATED_EMISSION
	mat = float(entityId);
	#endif

	//Color & Position
    color = gl_Color;

	gl_Position = ftransform();
}

#endif