//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_BLOCK

#ifdef FSH

//Varyings//
in vec2 texCoord, lightMapCoord;
in vec3 sunVec, upVec, eastVec;
in vec3 normal;
in vec4 color;

//Uniforms//
uniform int blockEntityId;

uniform float frameTimeCounter;
uniform float viewWidth, viewHeight, aspectRatio;
uniform float nightVision;

#ifdef OVERWORLD
uniform float rainStrength;
#endif

#if defined OVERWORLD || defined END
uniform float timeBrightness, timeAngle;
#endif

uniform vec3 cameraPosition;

uniform sampler2D texture, noisetex;

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

#if defined BLOOM || defined INTEGRATED_SPECULAR
#include "/lib/util/encode.glsl"
#endif

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;
	float emission = 0.0;

	if (albedo.a > 0.001) {
		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		vec3 viewPos = ToNDC(screenPos);
		vec3 worldPos = ToWorld(viewPos);
		vec2 lightmap = clamp(lightMapCoord, 0.0, 1.0);

		if (blockEntityId == 21) {
			emission = pow2(length(albedo.rgb)) * float(albedo.r < albedo.g);
		}

		if (blockEntityId == 22) {
			if (float(albedo.r > albedo.g * 1.55) > 0.9) {
				albedo.rgb = pow(albedo.rgb, vec3(1.25)) * 1.25;
			}
		}

		getSceneLighting(albedo.rgb, viewPos, worldPos, normal, lightmap, emission, 0.0, 0.0);

		if (blockEntityId == 20) {
			vec2 portalCoordPlayerPos = (worldPos.xz + cameraPosition.xz) * 0.2;

			float portalNoise = texture2D(noisetex, portalCoordPlayerPos * 0.1).r * 0.25 + 0.375;
			float portal0 = texture2D(texture,  portalCoordPlayerPos.rg * 0.50 + vec2(0.0, frameTimeCounter * 0.012)).r * 3.00;
			float portal1 = texture2D(texture,  portalCoordPlayerPos.gr * 0.75 + vec2(0.0, frameTimeCounter * 0.009)).r * 2.50;
			float portal2 = texture2D(texture,  portalCoordPlayerPos.rg * 1.00 + vec2(0.0, frameTimeCounter * 0.006)).r * 1.75;
			float portal3 = texture2D(texture,  portalCoordPlayerPos.gr * 1.25 + vec2(0.0, frameTimeCounter * 0.003)).r * 1.25;
			
			albedo.rgb = pow2(portalNoise) * endAmbientCol + portal3 * vec3(0.3, 0.2, 0.5) + portal2 * vec3(0.4, 0.2, 0.4) + portal1 * vec3(0.2, 0.4, 0.4) + portal0 * vec3(0.2, 0.3, 0.5);
			emission = pow4(length(albedo.rgb)) * 16.0;
		}
	}

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;

	#ifndef INTEGRATED_SPECULAR
		#ifdef BLOOM
		/* DRAWBUFFERS:02 */
		gl_FragData[1] = vec4(EncodeNormal(normal), emission, 0.0);
		#endif
	#else
		/* DRAWBUFFERS:06 */
		gl_FragData[1] = vec4(albedo.rgb, 0.05);

		#if defined BLOOM || defined INTEGRATED_SPECULAR
		/* DRAWBUFFERS:062 */
		gl_FragData[2] = vec4(EncodeNormal(normal), emission, 0.0);
		#endif
	#endif
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
#ifdef TAA
uniform int frameCounter;

uniform float viewWidth, viewHeight;
#endif

#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

uniform mat4 gbufferModelView;

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

	//Color & Position
    color = gl_Color;

	gl_Position = ftransform();

	#ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif