//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

#ifdef VC
in vec3 sunVec, upVec;
#endif

//Uniforms//
#ifdef VC
uniform int moonPhase;

#ifdef VL
uniform int isEyeInWater;
#endif

uniform float far, near, frameTimeCounter;
uniform float timeAngle, timeBrightness, rainStrength;
uniform float blindFactor;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition, skyColor;
#endif

uniform sampler2D colortex0;

#ifdef VC
uniform sampler2D noisetex;
uniform sampler2D depthtex0, depthtex1;
uniform sampler2D colortex1;
uniform sampler2DShadow shadowtex0, shadowtex1;

uniform mat4 gbufferProjectionInverse;

#if defined VC && defined SHADOW_COLOR
uniform sampler2D shadowcolor0;
#endif

uniform mat4 shadowModelView, shadowProjection;
uniform mat4 gbufferModelViewInverse;
#endif

//Common Variables//
#ifdef VC
float eBS = eyeBrightnessSmooth.y / 240.0;
float ug = mix(clamp((cameraPosition.y - 56.0) / 16.0, 0.0, 1.0), 1.0, eBS);
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
#endif

//Includes//
#ifdef VC
#include "/lib/color/lightColor.glsl"
#include "/lib/util/blueNoiseDithering.glsl"
#include "/lib/atmosphere/spaceConversion.glsl"
#include "/lib/atmosphere/volumetricEffects.glsl"
#endif

//Program//
void main() {
	vec3 color = pow(texture2D(colortex0, texCoord).rgb, vec3(2.2));
	vec4 vlOut1 = vec4(0.0);
	vec4 vlOut2 = vec4(0.0);

	#ifdef VC
	float dither = getBlueNoise(gl_FragCoord.xy);

	#ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

	vec2 newTexCoord = texCoord * VOLUMETRICS_RENDER_SCALE;
	vec4 translucent = texture2D(colortex1, newTexCoord);

	float z0 = texture2D(depthtex0, newTexCoord).r;
	float z1 = texture2D(depthtex1, newTexCoord).r;

	vec4 screenPos = vec4(newTexCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	computeVolumetricEffects(translucent, viewPos.xyz, newTexCoord, getLinearDepth2(z0), getLinearDepth2(z1), dither, vlOut1, vlOut2);
	vlOut1 = sqrt(vlOut1);
	vlOut2 = sqrt(vlOut2);

	if (isEyeInWater != 1) vlOut1 *= ug;
	vlOut2 *= ug;

	#if MC_VERSION >= 11900
	vlOut1 *= 1.0 - darknessFactor;
	vlOut2 *= 1.0 - darknessFactor;
	#endif

	vlOut1 *= 1.0 - blindFactor;
	vlOut2 *= 1.0 - blindFactor;
	#endif

	/* DRAWBUFFERS:034 */
	gl_FragData[0].rgb = color;
	gl_FragData[1] = vlOut1;
	gl_FragData[2] = vlOut2;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

#ifdef VC
out vec3 sunVec, upVec;
#endif

//Uniforms//
#ifdef VC
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Sun Vector
	#ifdef VC
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	upVec = normalize(gbufferModelView[1].xyz);
	#endif

	//Position
	gl_Position = ftransform();
}


#endif