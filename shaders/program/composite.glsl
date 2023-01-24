//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

#ifdef VL
in vec3 sunVec, upVec;
#endif

//Uniforms//
#ifdef VL
uniform int isEyeInWater;

uniform float far, near;
uniform float frameTimeCounter;
uniform float timeAngle, timeBrightness, rainStrength;
uniform float blindFactor;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition, skyColor;
#endif

uniform sampler2D colortex0;

#ifdef VL
uniform sampler2D noisetex;
uniform sampler2D colortex1;
uniform sampler2D depthtex0, depthtex1;

#ifdef SHADOW_COLOR
uniform sampler2D shadowcolor0;
#endif

#ifdef VL_CLOUDY_NOISE
uniform sampler2D shadowcolor1;
#endif

uniform sampler2DShadow shadowtex0, shadowtex1;

uniform mat4 shadowModelView, shadowProjection;
uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;
#endif

//Common Variables//
#ifdef VL
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.025, 0.0, 0.1) * 10.0;
#endif

//Includes//
#ifdef VL
#include "/lib/atmosphere/spaceConversion.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/util/blueNoiseDithering.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/atmosphere/volumetricLight.glsl"
#endif

//Program//
void main() {
	vec3 color = pow(texture2D(colortex0, texCoord).rgb, vec3(2.2));
	vec3 vl = vec3(0.0);

	#ifdef VL
	vec3 translucent = texture2D(colortex1, texCoord).rgb;

	float blueNoiseDither = getBlueNoise(gl_FragCoord.xy);

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + frameTimeCounter * 16.0);
	#endif

	computeVolumetricLight(vl, translucent, blueNoiseDither);
	#endif

	/* DRAWBUFFERS:06 */
	gl_FragData[0].rgb = color;
	gl_FragData[1] = vec4(sqrt(vl), int(vl != vec3(0.0)));
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
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Sun Vector
	#ifdef VL
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * PI) * -0.5 + 0.5 - ang) / 3.0) * TAU;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	upVec = normalize(gbufferModelView[1].xyz);
	#endif

	//Position
	gl_Position = ftransform();
}


#endif