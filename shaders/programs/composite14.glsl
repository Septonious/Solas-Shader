#include "/lib/common.glsl"

#define COMPOSITE14

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
uniform int isEyeInWater;

#ifdef LENS_FLARE
#ifdef OVERWORLD
uniform float shadowFade;
#endif

uniform float timeBrightness, timeAngle, wetness;
uniform float blindFactor;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif
#endif

uniform float aspectRatio;
uniform float viewWidth, viewHeight;

#ifdef DOF
#ifndef MANUAL_FOCUS
uniform float centerDepthSmooth;
#else
float centerDepthSmooth = ((DOF_FOCUS - near) * far) / ((far - near) * DOF_FOCUS);
#endif
#endif

uniform ivec2 eyeBrightnessSmooth;

#ifdef LENS_FLARE
uniform vec3 cameraPosition, sunPosition;
#endif

#ifdef NETHER
uniform vec3 fogColor;
#endif

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D depthtex1;

#ifdef BLOOM
uniform sampler2D colortex1;

uniform mat4 gbufferProjectionInverse;
#endif

#if defined DOF || defined LENS_FLARE
uniform mat4 gbufferProjection;
#endif

#ifdef LENS_FLARE
uniform mat4 gbufferModelView;
#endif

// Pipeline Options //
const bool colortex0MipmapEnabled = true;
const bool colortex1MipmapEnabled = true;
const bool colortex2Clear = false;

// Global Variables //
#ifdef LENS_FLARE
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

float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, sqrt(eBS));
float sunVisibility = clamp((dot( sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
#endif

// Includes //
#include "/lib/util/bayerDithering.glsl"
#include "/lib/post/tonemap.glsl"

#ifdef BLOOM
#include "/lib/post/getBloom.glsl"
#endif

#ifdef DOF
#include "/lib/util/ToView.glsl"
#include "/lib/post/computeDOF.glsl"
#endif

#ifdef LENS_FLARE
#include "/lib/color/lightColor.glsl"
#include "/lib/post/lensFlare.glsl"
#endif

// Main //
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	vec3 temporalColor = vec3(0.0);
	#ifdef TAA
		 temporalColor = texture2D(colortex2, texCoord).gba;
	#endif

	float temporalData = 0.0;

	//Lens Flare Parameters
	#ifdef LENS_FLARE
	float pixelWidth = 1.0 / viewWidth;
	float pixelHeight = 1.0 / viewHeight;
	float tempVisibleSun = texture2D(colortex2, vec2(3.0 * pixelWidth, pixelHeight)).r;
	#endif

	//Depth of Field & Tilt Shift
	#ifdef DOF
	float z1 = texture2D(depthtex1, texCoord).r;
	color = getDepthOfField(color, texCoord, z1);
	#endif

	//Bloom
	#ifdef BLOOM
	getBloom(color, texCoord);
	#endif

	//Tonemap & Film Grain
	color = Uncharted2Tonemap(color * TONEMAP_BRIGHTNESS) / Uncharted2Tonemap(vec3(TONEMAP_WHITE_THRESHOLD));
	color = pow(color, vec3(1.0 / 2.2));
	colorSaturation(color);
	color += (Bayer8(gl_FragCoord.xy) - 0.25) / 128.0;

	//Lens Flare
	#ifdef LENS_FLARE
	vec2 lightPos = getLightPos();
	float truePos = sign(sunVec.z);
	      
    float visibleSun = float(texture2D(depthtex1, lightPos + 0.5).r >= 1.0);
		  visibleSun *= max(1.0 - isEyeInWater, eBS) * (1.0 - wetness) * caveFactor;

	#if MC_VERSION >= 11900
		  visibleSun *= (1.0 - max(blindFactor, darknessFactor));
	#endif
	
	float multiplier = tempVisibleSun * LENS_FLARE_STRENGTH * (length(color) * 0.25 + 0.25);

	#ifdef OVERWORLD
		  multiplier *= shadowFade;
	#endif

	if (multiplier > 0.001) LensFlare(color, lightPos, truePos, multiplier);

	if (texCoord.x > 2.0 * pixelWidth && texCoord.x < 4.0 * pixelWidth && texCoord.y < 2.0 * pixelHeight)
		temporalData = mix(tempVisibleSun, visibleSun, 0.125);
	#endif

	/* DRAWBUFFERS:12 */
	gl_FragData[0].rgb = color;
	gl_FragData[1] = vec4(temporalData, temporalColor);
}

#endif

//**//**//**//**//**//**//**//**//**//**//**//**//**//**//

#ifdef VSH

// VSH Data //
out vec2 texCoord;

void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
}

#endif