//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_7

#ifdef FSH

//Varyings//
in vec2 texCoord;

#ifdef WATER_FOG
#if defined OVERWORLD || defined END
in vec3 sunVec, upVec;
#endif
#endif

//Uniforms//
#ifdef WATER_FOG
uniform int isEyeInWater;

uniform float blindFactor;

#if defined OVERWORLD || defined END
uniform float timeBrightness, timeAngle, rainStrength;
#endif

uniform ivec2 eyeBrightnessSmooth;
#endif

#ifdef WATER_REFRACTION
uniform float frameTimeCounter;
#endif

#ifdef WATER_REFRACTION
uniform vec3 cameraPosition;

uniform sampler2D colortex2;
uniform sampler2D noisetex;
#endif

uniform sampler2D colortex0;

#if defined WATER_FOG || defined WATER_REFRACTION
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
#endif

#ifdef WATER_REFRACTION
uniform mat4 gbufferModelViewInverse;
#endif

//Common Variables//
#ifdef WATER_FOG
float eBS = eyeBrightnessSmooth.y / 240.0;

#if defined OVERWORLD || defined END
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
#endif
#endif

//Includes//
#ifdef WATER_FOG
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/water/waterFog.glsl"
#endif

#ifdef WATER_REFRACTION
#include "/lib/water/waterRefraction.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#if defined WATER_FOG || defined WATER_REFRACTION
	float z0 = texture2D(depthtex0, texCoord).r;
	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;
	#endif

	#ifdef WATER_REFRACTION
	float water = texture2D(colortex2, texCoord).a;

	if (water > 0.9) {
		vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos.xyz;
		vec3 pos = worldPos + cameraPosition;
		vec2 refractionCoord = getRefraction(texCoord, pos);

		color = texture2D(colortex0, refractionCoord).rgb;
	}
	#endif

	#ifdef WATER_FOG
	if (isEyeInWater == 1){
		vec4 waterFog = getWaterFog(viewPos.xyz);
		color = mix(sqrt(color), sqrt(waterFog.rgb), waterFog.a);
		color *= color;
	}
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

#ifdef WATER_FOG
#if defined OVERWORLD || defined END
out vec3 sunVec, upVec;
#endif

//Uniforms
#if defined OVERWORLD || defined END
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif
#endif

void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Sun & Other Vectors
	#ifdef WATER_FOG
    #if defined OVERWORLD
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
    #elif defined END
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
    sunVec = normalize((gbufferModelView * vec4(vec3(0.0, sunRotationData * 2000.0), 1.0)).xyz);
    #endif
	
	#if defined OVERWORLD || defined END
	upVec = normalize(gbufferModelView[1].xyz);
	#endif
	#endif

	//Position
	gl_Position = ftransform();
}

#endif