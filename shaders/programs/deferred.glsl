#define DEFERRED

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
uniform int vxRenderDistance;
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef DISTANT_HORIZONS
uniform int dhRenderDistance;
#endif

#ifdef OVERWORLD
uniform int worldDay;
uniform int moonPhase;
uniform int worldTime;

uniform float shadowFade;
uniform float rainStrength;
uniform float timeAngle, timeBrightness, wetness;

#if MC_VERSION >= 12104
uniform float isPaleGarden;
#endif

uniform vec3 skyColor;
#endif

uniform float viewWidth, viewHeight;
uniform float far, near;
#ifdef DISTANT_HORIZONS
uniform float dhFarPlane;
#endif
uniform float blindFactor, nightVision;
#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform float frameTimeCounter;

uniform ivec2 eyeBrightnessSmooth;

#if defined END && MC_VERSION >= 12100
uniform float endFlashIntensity;

uniform vec3 endFlashPosition;
#endif

uniform vec3 cameraPosition;

#ifdef NETHER
uniform vec3 fogColor;
#endif

#ifdef VOLUMETRIC_CLOUDS
uniform vec4 lightningBoltPosition;
#endif

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
#ifdef DISTANT_HORIZONS
uniform sampler2D dhDepthTex0;
#endif
uniform sampler2D noisetex;

#ifdef MILKY_WAY
uniform sampler2D depthtex2;
#endif

#if defined VOLUMETRIC_CLOUDS || defined END_DISK
uniform sampler2DShadow shadowtex1;

uniform mat4 shadowModelView, shadowProjection;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

#ifdef DISTANT_HORIZONS
uniform mat4 dhProjectionInverse;
#endif

// Pipeline Options //
const bool colortex4Clear = false;
const bool colortex5Clear = false;

// Global Variables //
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

#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = fmix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, sqrt(eBS));
float sunVisibility = clamp((dot( sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#endif

// Includes //
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/color/lightColor.glsl"

#ifdef OVERWORLD
#include "/lib/atmosphere/sky.glsl"

#ifdef ROUND_SUN_MOON
#include "/lib/atmosphere/sunMoon.glsl"
#endif
#endif

#if defined VOLUMETRIC_CLOUDS || defined END_DISK
#include "/lib/atmosphere/spaceConversion.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/lighting/lightning.glsl"
#include "/lib/atmosphere/volumetricClouds.glsl"
#endif

#include "/lib/atmosphere/skyEffects.glsl"
#include "/lib/atmosphere/fog.glsl"

// Main //
void main() {
    vec3 color = texture2D(colortex0, texCoord).rgb;

    float z0 = texture2D(depthtex0, texCoord).r;
	#ifdef DISTANT_HORIZONS
	float dhZ = texture2D(dhDepthTex0, texCoord).r;
	#endif

	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		 viewPos /= viewPos.w;
	vec4 worldPos = gbufferModelViewInverse * vec4(viewPos.xyz, 1.0);
		 worldPos.xyz /= worldPos.w;

    #if defined OVERWORLD
    vec3 atmosphereColor = getAtmosphere(viewPos.xyz);
		 atmosphereColor *= 1.0 + Bayer8(gl_FragCoord.xy) / 64.0;
	#elif defined NETHER
	vec3 atmosphereColor = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 atmosphereColor = endAmbientColSqrt * 0.175;
	#endif

	#if defined OVERWORLD || defined END
	vec3 nViewPos = normalize(viewPos.xyz);

	float VoU = dot(nViewPos, upVec);
	float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
	float VoM = clamp(dot(nViewPos, -sunVec), 0.0, 1.0);
	#endif

    //Volumetric Clouds
	vec4 vc = vec4(0.0);

	#ifdef DISTANT_HORIZONS
	float cloudDepth = 2.0 * dhFarPlane;
	#else
	float cloudDepth = 2.0 * far;
	#endif

	#if defined VOLUMETRIC_CLOUDS || defined END_DISK
	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;
	#ifdef TAA
	      blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif
	#endif
	
	#ifdef VOLUMETRIC_CLOUDS
	computeVolumetricClouds(vc, atmosphereColor, z0, blueNoiseDither, cloudDepth);
	#endif

	#ifdef END_DISK
	computeEndVolumetricClouds(vc, atmosphereColor, z0, blueNoiseDither, cloudDepth);
	#endif

	//Sky
    vec3 skyColor = atmosphereColor;

	#ifndef NETHER
    float occlusion = vc.a;
    float nebulaFactor = 0.0;

    #ifdef ROUND_SUN_MOON
    drawSunMoon(skyColor, worldPos.xyz, nViewPos, VoU, VoS, VoM, caveFactor, occlusion);
    #endif

	#if MC_VERSION >= 12104 && defined OVERWORLD
    VoU *= 1.0 - isPaleGarden;
	#endif

    if (VoU > 0.0) {
        #ifdef PLANAR_CLOUDS
        drawPlanarClouds(skyColor, atmosphereColor, worldPos.xyz, viewPos.xyz, VoU, caveFactor, vc.a, occlusion);
        #endif

        #ifdef AURORA
        drawAurora(skyColor, worldPos.xyz, VoU, caveFactor, vc.a, occlusion - vc.a);
        #endif

        #ifdef MILKY_WAY
        drawMilkyWay(skyColor, worldPos.xyz, VoU, caveFactor, nebulaFactor, occlusion);
        #endif

        #ifdef STARS
        drawStars(skyColor, worldPos.xyz, VoU, VoS, caveFactor, nebulaFactor, occlusion, 0.7);

		#ifdef SHOOTING_STARS
		getShootingStars(skyColor, worldPos.xyz, VoU, VoS);
		#endif
        #endif

        #ifdef RAINBOW
        getRainbow(skyColor, worldPos.xyz, VoU, 1.75, 0.05, caveFactor);
        #endif
    }

    #ifdef END_NEBULA
    drawEndNebula(skyColor, worldPos.xyz, VoU, VoS);
    #endif

    #ifdef END_STARS
    drawStars(skyColor, worldPos.xyz, VoU, VoS, 1.0, nebulaFactor, 0.0, 0.85);
    #endif
	#endif

    skyColor *= 1.0 - blindFactor;
    #if MC_VERSION >= 11900
    skyColor *= 1.0 - darknessFactor;
    #endif

	#ifndef DISTANT_HORIZONS
	if (z0 == 1.0) color = skyColor;
	#else
	if (dhZ == 1.0 && z0 == 1.0) color = skyColor;
	#endif

	//Volumetric Clouds
	#if defined VOLUMETRIC_CLOUDS || defined END_DISK
	vc.rgb = pow(vc.rgb, vec3(1.0 / 2.2));

	#ifdef DISTANT_HORIZONS
	cloudDepth /= (2.0 * dhFarPlane);
	#else
	float farPlane = far + vxRenderDistance * 16.0;
	cloudDepth /= (2.0 * farPlane);
	#endif

	color = fmix(color, vc.rgb, vc.a);
	#endif

    /* DRAWBUFFERS:045 */
    gl_FragData[0].rgb = color;
	gl_FragData[1].rgb = pow(color.rgb, vec3(0.125)) * 0.5;
	gl_FragData[2].r = cloudDepth;
}

#endif


//**//**//**//**//**//**//**//**//**//**//**//**//**//**//


#ifdef VSH

// VSH Data //
out vec2 texCoord;

// Main //
void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}

#endif