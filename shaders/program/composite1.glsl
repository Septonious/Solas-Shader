//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_3

#ifdef FSH

//Varyings//
in vec2 texCoord;

#ifdef WATER_FOG
in vec3 sunVec, upVec;
#endif

//Uniforms//
#if defined WATER_FOG || defined REFRACTION
uniform int isEyeInWater;
#endif

#ifdef WATER_FOG
#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform float blindFactor;
uniform float timeBrightness, timeAngle, rainStrength, shadowFade;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 fogColor;
#endif

uniform sampler2D colortex0;

#ifdef REFRACTION
uniform float aspectRatio;
uniform float frameTimeCounter;

uniform sampler2D colortex3;

uniform mat4 gbufferProjection;
#endif

#if defined WATER_FOG || defined REFRACTION
uniform sampler2D depthtex0, depthtex1;

uniform mat4 gbufferProjectionInverse;
#endif

//Common Variables//
#ifdef WATER_FOG
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.025, 0.0, 0.1) * 10.0;
#endif

//Includes//
#if defined WATER_FOG || defined REFRACTION
#include "/lib/util/ToView.glsl"

#ifdef REFRACTION
#include "/lib/util/encode.glsl"
#endif

#ifdef WATER_FOG
#include "/lib/color/dimensionColor.glsl"
#include "/lib/water/waterFog.glsl"
#endif
#endif

void main() {
	vec2 newTexCoord = texCoord;
	vec3 color = texture2D(colortex0, newTexCoord).rgb;

	#if defined WATER_FOG || defined REFRACTION
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;
	
	vec3 screenPos = vec3(texCoord, z0);
	vec3 viewPos = ToView(screenPos);
	#endif

	#ifdef REFRACTION
	if (z1 > z0 && z0 > 0.56) {
		float fovScale = gbufferProjection[1][1] / 1.37;
		vec3 distort = texture2D(colortex3, texCoord).rgb;

		if (distort.xy != vec2(0.0)) {
			 distort = DecodeNormal(distort.xy) * REFRACTION_STRENGTH;
			 distort.xy *= vec2(1.0 / aspectRatio, 1.0) * fovScale / max(length(viewPos.xyz), 8.0);

			vec2 newCoord = clamp(texCoord + distort.xy, 0.0, 1.0);

			z0 = texture2D(depthtex0, newCoord).r;
			z1 = texture2D(depthtex1, newCoord).r;

			color.rgb = texture2D(colortex0, newCoord).rgb;

			screenPos = vec3(newCoord.xy, z0);
			viewPos = ToView(screenPos);
		}
	}
	#endif

	#ifdef WATER_FOG
	if (isEyeInWater == 1){
		vec4 waterFog = getWaterFog(viewPos);
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
out vec3 sunVec, upVec;

//Uniforms
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Sun & Other Vectors
	#ifdef WATER_FOG
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
	#endif

	//Position
	gl_Position = ftransform();
}

#endif