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
uniform sampler2D noisetex, colortex3;
uniform sampler2D depthtex0, depthtex1;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
#endif

//Common Variables//
#if defined PBR || defined GENERATED_SPECULAR
const bool colortex0MipmapEnabled = true;

#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, eBS);
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
#endif
#endif

//Includes//
#if defined PBR || defined GENERATED_SPECULAR
#include "/lib/util/ToScreen.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/encode.glsl"

#ifdef OVERWORLD
#include "/lib/color/lightColor.glsl"
#include "/lib/atmosphere/sky.glsl"
#endif

#include "/lib/pbr/raytracer.glsl"
#include "/lib/pbr/simpleReflection.glsl"
#endif

void main() {
	vec4 color = texture2D(colortex0, texCoord);

	#if defined PBR || defined GENERATED_SPECULAR
	vec4 gbuffersData = texture2D(colortex3, texCoord);
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;
	float entityFlag = float(gbuffersData.a >= 0.073 && gbuffersData.a <= 0.075);

	if (gbuffersData.a > 0.01 && gbuffersData.a <= 0.95 && entityFlag < 1.0 && z0 > 0.56 && z0 >= z1 && z1 < 1.0) {
		vec3 normal = decodeNormal(gbuffersData.rg);
		vec3 viewPos = ToView(vec3(texCoord, z0));

		float fresnel = clamp(1.0 + dot(normal, normalize(viewPos)), 0.0, 1.0);

		getReflection(color, viewPos, normal, fresnel * fresnel, gbuffersData.a);
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
	getSunVector(gbufferModelView, timeAngle, sunVec);
	upVec = normalize(gbufferModelView[1].xyz);
	#endif

	//Position
	gl_Position = ftransform();
}

#endif