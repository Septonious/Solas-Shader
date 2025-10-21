#define COMPOSITE_3

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
#if defined PBR || defined GENERATED_SPECULAR || defined REFRACTION
uniform int isEyeInWater;

#ifdef TAA
uniform int frameCounter;
#endif

uniform float frameTimeCounter;
uniform float aspectRatio;
uniform float viewHeight, viewWidth;
#endif

uniform float blindFactor;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

#ifdef OVERWORLD
uniform float wetness;
uniform float timeAngle, timeBrightness;

uniform vec3 skyColor;
uniform vec3 cameraPosition;
#endif

uniform ivec2 eyeBrightnessSmooth;

#ifdef NETHER
uniform vec3 fogColor;
#endif

uniform sampler2D colortex0;

#if defined PBR || defined GENERATED_SPECULAR || defined REFRACTION
uniform sampler2D noisetex, colortex3;
uniform sampler2D depthtex0, depthtex1;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
#endif

// Global Variables //
#if defined PBR || defined GENERATED_SPECULAR || defined REFRACTION
const bool colortex0MipmapEnabled = true;

#if defined OVERWORLD
const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
float fractTimeAngle = fract(timeAngle - 0.25);
float ang = (fractTimeAngle + (cos(fractTimeAngle * 3.14159265358979) * -0.5 + 0.5 - fractTimeAngle) / 3.0) * 6.28318530717959;
vec3 sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
#elif defined END
const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
vec3 sunVec = normalize((gbufferModelView * vec4(1.0, sunRotationData * 2000.0, 1.0)).xyz);
#else
vec3 sunVec = vec3(0.0);
#endif

vec3 upVec = normalize(gbufferModelView[1].xyz);
vec3 eastVec = normalize(gbufferModelView[0].xyz);

float eBS = eyeBrightnessSmooth.y / 240.0;

#ifdef OVERWORLD
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, sqrt(eBS));
float sunVisibility = clamp((dot( sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#endif
#endif

//Includes//
#if defined PBR || defined GENERATED_SPECULAR || defined REFRACTION
#include "/lib/util/ToScreen.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/encode.glsl"
#include "/lib/color/lightColor.glsl"

#ifdef OVERWORLD
#include "/lib/atmosphere/sky.glsl"
#endif

#ifdef REFRACTION
#include "/lib/post/chromaticAberration.glsl"
#endif

#include "/lib/pbr/raytracer.glsl"
#include "/lib/pbr/simpleReflection.glsl"
#endif

void main() {
	vec4 color = texture2D(colortex0, texCoord);

    #if defined PBR || defined GENERATED_SPECULAR || defined REFRACTION
    vec4 gbuffersData = texture2D(colortex3, texCoord);

	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	vec3 screenPos = vec3(texCoord, z0);
	vec3 viewPos = ToView(screenPos);
    #endif

	#ifdef REFRACTION
	if (z1 > z0) {
		vec3 distort = texture2D(colortex3, texCoord).rgb;

		if (distort.xy != vec2(0.0)) {
			float fovScale = gbufferProjection[1][1] / 1.37;

			distort = decodeNormal(distort.xy) * REFRACTION_STRENGTH * (1.0 + length(viewPos.y) * float(isEyeInWater == 1));
			distort.xy *= vec2(1.0 / aspectRatio, 1.0) * fovScale / max(length(viewPos.xyz), 8.0);

			vec2 newCoord = clamp(texCoord + distort.xy, 0.0, 1.0);

			float distortMask = texture2D(colortex3, newCoord).b;
			float water = float(distortMask > 0.79 && distortMask < 0.81);
			//float glass = float(distortMask > 0.39 && distortMask < 0.41);

			if (water > 0.0 && z0 > 0.56) {
				z0 = texture2D(depthtex0, newCoord).r;
				z1 = texture2D(depthtex1, newCoord).r;
				color.rgb = texture2D(colortex0, newCoord).rgb;
				//if (water > 0.5) {
					//getWaterChromaticAberration(colortex0, color.rgb, newCoord, distort.xy * float(distortMask > 0.0));
				//}
			}

			screenPos = vec3(newCoord.xy, z0);
			viewPos = ToView(screenPos);
		}
	}
	#endif

	#if defined PBR || defined GENERATED_SPECULAR
	float smoothness = gbuffersData.a;
    #ifdef PBR
          smoothness *= smoothness;
          smoothness /= 2.0 - smoothness;
    #endif

	float skyLightMap = gbuffersData.b * 2.0;

	if (gbuffersData.a > 0.01 && gbuffersData.a <= 0.95 && z0 > 0.56 && z0 >= z1 && z1 < 1.0) {
		vec3 normal = decodeNormal(gbuffersData.rg);
        vec3 viewPos2 = ToView(vec3(texCoord, z0));

		float fresnel = clamp(1.0 + dot(normal, normalize(viewPos2)), 0.0, 1.0);
        #ifdef PBR
              fresnel *= fresnel;
        #endif

		getReflection(color, viewPos2, normal, fresnel, smoothness, skyLightMap);
	}
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;
}

#endif

//**//**//**//**//**//**//**//**//**//**//**//**//**//**//

#ifdef VSH

// VSH Data //
out vec2 texCoord;

// Main //
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}

#endif