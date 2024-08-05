//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

#if (defined PBR || defined GENERATED_SPECULAR) && defined OVERWORLD
in vec3 sunVec, upVec;
#endif

//Uniforms//
#if defined PBR || defined GENERATED_SPECULAR
uniform int isEyeInWater;

#ifdef TAA
uniform int frameCounter;
#endif

uniform float viewHeight, viewWidth;
#endif

#ifdef OVERWORLD
uniform float wetness;
uniform float blindFactor;
uniform float timeAngle, timeBrightness;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

#ifdef AURORA
uniform float isSnowy;
uniform int moonPhase;
#endif

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 skyColor;
uniform vec3 cameraPosition;
#endif

uniform sampler2D colortex0;

#if defined PBR || defined GENERATED_SPECULAR
uniform sampler2D noisetex, colortex3, colortex7;
uniform sampler2D depthtex0, depthtex1;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
#endif

//Common Variables//
#if defined PBR || defined GENERATED_SPECULAR
const bool colortex0MipmapEnabled = true;
const bool colortex3MipmapEnabled = true;

vec2 viewResolution = vec2(viewWidth, viewHeight);

#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, eBS);
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
#endif
#endif

//Includes//
#if defined PBR || defined GENERATED_SPECULAR
#ifdef OVERWORLD
#include "/lib/color/lightColor.glsl"
#include "/lib/atmosphere/sky.glsl"
#endif

#include "/lib/util/ToScreen.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/encode.glsl"
#include "/lib/util/bayerDithering.glsl"
#include "/lib/pbr/raytracer.glsl"
#include "/lib/pbr/simpleReflection.glsl"
#endif

void main() {
	vec4 color = texture2D(colortex0, texCoord);

	#if defined PBR || defined GENERATED_SPECULAR
	vec4 terrainData = texture2D(colortex3, texCoord);
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	if (terrainData.a > 0.01 && terrainData.a <= 0.95 && z0 > 0.56 && z0 >= z1) {
		vec3 normal = decodeNormal(terrainData.rg);
		vec3 viewPos = ToView(vec3(texCoord, z0));

		float fresnel = clamp(1.0 + dot(normal, normalize(viewPos)), 0.0, 1.0) * terrainData.a;

		getReflection(color, viewPos, normal, fresnel, terrainData.a);
	}
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

#if (defined PBR || defined GENERATED_SPECULAR) && defined OVERWORLD
out vec3 sunVec, upVec;
#endif

//Uniforms//
#if (defined PBR || defined GENERATED_SPECULAR) && defined OVERWORLD
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Sun Vector
	#if (defined PBR || defined GENERATED_SPECULAR) && defined OVERWORLD
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