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
#if defined WATER_FOG || defined WATER_REFRACTION
uniform int isEyeInWater;
#endif

#ifdef SSPT
uniform float far, near;
uniform float viewWidth, viewHeight;
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

#ifdef WATER_REFRACTION
uniform float frameTimeCounter;

uniform vec3 cameraPosition;

uniform sampler2D colortex4;

#ifdef SSPT
uniform sampler2D colortex2, colortex3;
#endif

#ifdef BLOCKY_CLOUDS
uniform sampler2D noisetex;
#else
uniform sampler2D shadowcolor1;
#endif

uniform mat4 gbufferModelViewInverse;
#endif

#if defined WATER_FOG || defined WATER_REFRACTION
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
#endif

//Common Variables//
#ifdef WATER_FOG
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.025, 0.0, 0.1) * 10.0;
#endif

//Includes//
#if defined WATER_FOG || defined WATER_REFRACTION
#include "/lib/util/ToView.glsl"

#ifdef WATER_REFRACTION
#include "/lib/util/ToWorld.glsl"
#include "/lib/water/waterRefraction.glsl"
#endif

#ifdef WATER_FOG
#include "/lib/color/dimensionColor.glsl"
#include "/lib/water/waterFog.glsl"
#endif
#endif

#ifdef SSPT
#include "/lib/util/encode.glsl"
#include "/lib/filters/ssptDenoiser.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#if defined WATER_FOG || defined WATER_REFRACTION
	float z0 = texture2D(depthtex0, texCoord).r;
	vec3 viewPos = ToView(vec3(texCoord, z0));

	#ifdef WATER_FOG
	if (isEyeInWater == 1){
		vec4 waterFog = getWaterFog(viewPos);
		color = mix(sqrt(color), sqrt(waterFog.rgb), waterFog.a);
		color *= color;
	}
	#endif

	#ifdef WATER_REFRACTION
	float waterData = texture2D(colortex4, texCoord).a;

	if (waterData > 0.0 && waterData < 0.004000001 && isEyeInWater == 0 && z0 > 0.56) {
		vec3 worldPos = ToWorld(viewPos);
		vec2 refractedCoord = getRefraction(worldPos + cameraPosition, viewPos);

		color = texture2D(colortex0, refractedCoord).rgb;
	}
	#endif
	#endif

	#ifdef SSPT
	vec3 sspt = NormalAwareBlur();
	color *= vec3(1.0) + sspt * SSPT_LUMINANCE;
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;

	#ifdef SSPT
	/* DRAWBUFFERS:03 */
	gl_FragData[1].rgb = sspt;
	#endif
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