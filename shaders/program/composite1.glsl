//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_1

#ifdef FSH

//Varyings//
in vec2 texCoord;

#ifdef VL
in vec3 sunVec, upVec;
#endif

//Uniforms//
#if defined VL || defined VCLOUDS
uniform float viewWidth, viewHeight;

#ifdef VL
uniform float timeAngle, timeBrightness, rainStrength;
#endif

#ifdef VCLOUDS
uniform sampler2D colortex4;
#endif

#ifdef VL
uniform sampler2D colortex1;
#endif
#endif

uniform sampler2D colortex0;

//Common Variables//
#ifdef VL
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
#endif

//Includes//
#if defined VL || defined VCLOUDS
#include "/lib/filters/blur.glsl"
#endif

#ifdef VL
#include "/lib/color/lightColor.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#if defined VL || defined VCLOUDS
	vec2 newTexCoord = texCoord * VOLUMETRICS_RESOLUTION;
	#endif

	#ifdef VL
    vec3 vl = getDiskBlur4(colortex1, newTexCoord, 1.5 / VOLUMETRICS_RESOLUTION).rgb;
	color += vl * vl * VL_STRENGTH * 0.25 * lightCol;
	#endif

	#ifdef VCLOUDS
    vec4 clouds = getDiskBlur8(colortex4, newTexCoord, 1.5 / VOLUMETRICS_RESOLUTION);

	color = mix(color, clouds.rgb, pow6(clouds.a));
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

#ifdef VL
out vec3 sunVec, upVec;
#endif

//Uniforms//
#ifdef VL
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Program//
void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Sun & Other Vectors
	#ifdef VL
    #if defined OVERWORLD
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
    #elif defined END
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