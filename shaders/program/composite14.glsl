//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

#ifdef LENS_FLARE
in vec3 sunVec, upVec;
#endif

//Uniforms//
uniform int frameCounter;

#ifdef LENS_FLARE
uniform int isEyeInWater;

uniform float timeAngle, wetness;
uniform float blindFactor;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif
#endif

uniform float viewWidth, viewHeight, aspectRatio;
uniform float far, near;

#ifdef BLOOM
#ifdef TAA
uniform float frameTimeCounter;
#endif

#ifdef OVERWORLD
uniform float timeBrightness;
#endif
#endif

#ifdef DOF
#ifndef MANUAL_FOCUS
uniform float centerDepthSmooth;
#else
float centerDepthSmooth = ((DOF_FOCUS - near) * far) / ((far - near) * DOF_FOCUS);
#endif
#endif

uniform ivec2 eyeBrightnessSmooth;
uniform vec3 cameraPosition;

#ifdef MOTION_BLUR
uniform vec3 previousCameraPosition;

uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView, gbufferModelViewInverse;

uniform sampler2D colortex3;
#endif

uniform sampler2D colortex0, colortex2;
uniform sampler2D noisetex;
uniform sampler2D depthtex0;

#ifdef LENS_FLARE
uniform vec3 sunPosition, skyColor;
uniform mat4 gbufferProjection;
#endif

#ifdef BLOOM
uniform sampler2D colortex1;

uniform mat4 gbufferProjectionInverse;
#endif

#ifdef DOF
uniform mat4 gbufferProjection;
#endif

//Optifine Constants//
const bool colortex0MipmapEnabled = true;
const bool colortex1MipmapEnabled = true;
const bool colortex2Clear = false;

//Common Variables//
#ifdef LENS_FLARE
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, eBS);
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
#endif

//Includes//
#include "/lib/util/bayerDithering.glsl"
#include "/lib/post/tonemap.glsl"

#ifdef FXAA
#include "/lib/antialiasing/fxaa.glsl"
#endif

#ifdef BLOOM
#include "/lib/post/getBloom.glsl"
#endif

#ifdef DOF
#include "/lib/util/ToView.glsl"
#include "/lib/post/computeDOF.glsl"
#endif

#ifdef MOTION_BLUR
#include "/lib/post/motionBlur.glsl"
#endif

#ifdef LENS_FLARE
#include "/lib/color/lightColor.glsl"
#include "/lib/post/lensFlare.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2DLod(colortex0, texCoord, 0).rgb;

	//Preset Variables
	float z0 = texture2D(depthtex0, texCoord).r;

    float dither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;
    #ifdef TAA
          dither = fract(dither + GOLDENRATIO * mod(float(frameCounter), 3600.0));
    #endif

	#ifdef LENS_FLARE
	float pixelWidth = 1.0 / viewWidth;
	float pixelHeight = 1.0 / viewHeight;
	float tempVisibleSun = texture2D(colortex2, vec2(3.0 * pixelWidth, pixelHeight)).r;
	#endif

	vec3 temporalColor = vec3(0.0);
	#ifdef TAA
		 temporalColor = texture2D(colortex2, texCoord).gba;
	#endif

	float temporalData = 0.0;

	//Fast Approximate Antialiasing
	#ifdef FXAA
	color = FXAA311(color);
	#endif

	//Motion Blur
	#ifdef MOTION_BLUR
	color = getMotionBlur(color, z0);
	#endif

	//Depth of Field & Tilt Shift
	#ifdef DOF
	color = getDepthOfField(color, texCoord, z0);
	#endif

	//Bloom
	#ifdef BLOOM
	getBloom(color, texCoord);
	#endif

	//Tonemapping
	color = Uncharted2Tonemap(color * TONEMAP_BRIGHTNESS) / Uncharted2Tonemap(vec3(TONEMAP_WHITE_THRESHOLD));
	color = pow(color, vec3(1.0 / 2.2));

	#ifdef LENS_FLARE
	vec2 lightPos = GetLightPos();
	float truePos = sign(sunVec.z);
	      
    float visibleSun = float(texture2D(depthtex0, lightPos + 0.5).r >= 1.0);
		  visibleSun *= max(1.0 - isEyeInWater, eBS) * (1.0 - max(blindFactor, darknessFactor)) * (1.0 - wetness) * caveFactor;
	
	float multiplier = tempVisibleSun * LENS_FLARE_STRENGTH * (length(color) * 0.25 + 0.25);

	if (multiplier > 0.001) LensFlare(color, lightPos, truePos, multiplier);

	if (texCoord.x > 2.0 * pixelWidth && texCoord.x < 4.0 * pixelWidth && texCoord.y < 2.0 * pixelHeight)
		temporalData = mix(tempVisibleSun, visibleSun, 0.125);
	#endif

	//Film Grain
    color += vec3((dither - 0.25) / 128.0);

	/* DRAWBUFFERS:12 */
	gl_FragData[0].rgb = color;
	gl_FragData[1] = vec4(temporalData, temporalColor);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

#ifdef LENS_FLARE
out vec3 sunVec, upVec;
#endif

//Uniforms//
#ifdef LENS_FLARE
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Includes//
#include "/lib/wmark/s0las_shader.glsl"

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy * float(chval == 0.1984);
	
	//Sun Vector
	#ifdef LENS_FLARE
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