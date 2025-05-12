//Settings//
#include "/lib/common.glsl"

#define DEFERRED

#ifdef FSH

//Varyings//
in vec2 texCoord;

#if defined OVERWORLD || defined END
in vec3 sunVec, upVec;
#endif

//Uniforms//
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef DISTANT_HORIZONS
uniform int dhRenderDistance;
#endif

#ifdef VC
uniform int worldDay;
uniform int worldTime;
#endif

#ifdef OVERWORLD
uniform int moonPhase;
#endif

uniform float viewWidth, viewHeight;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

#if MC_VERSION >= 12104
uniform float isPaleGarden;
#endif

uniform float far, near;
uniform float blindFactor;
uniform float nightVision;
uniform float frameTimeCounter;

#ifdef OVERWORLD
uniform float timeBrightness, timeAngle, rainStrength;
uniform float shadowFade;
uniform float wetness;
uniform float isSnowy;

uniform ivec2 eyeBrightnessSmooth;
#endif

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec3 cameraPosition;

#ifdef VC
uniform vec4 lightningBoltPosition;
#endif

#ifdef MILKY_WAY
uniform sampler2D depthtex2;
#endif

uniform sampler2D colortex0;
uniform sampler2D noisetex;
uniform sampler2D depthtex1;

#if defined VC || defined END_CLOUDY_FOG
uniform sampler2D shadowtex1;

#ifdef BLOCKY_CLOUDS
uniform sampler2D shadowcolor1;
#endif

uniform mat4 shadowModelView, shadowProjection;
#endif

#ifdef DISTANT_HORIZONS
uniform float dhFarPlane, dhNearPlane;

uniform sampler2D dhDepthTex0;
uniform mat4 dhProjectionInverse;
#endif

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

//Common Variables//
#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, eBS);
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
#endif

//Includes//
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/color/netherColor.glsl"

#if defined VC || defined END_CLOUDY_FOG
#include "/lib/atmosphere/spaceConversion.glsl"
#include "/lib/util/ToShadow.glsl"
#endif

#ifdef VC
#ifndef BLOCKY_CLOUDS
#include "/lib/lighting/lightning.glsl"
#include "/lib/atmosphere/volumetricClouds.glsl"
#else
#include "/lib/atmosphere/volumetricBlockyClouds.glsl"
#endif
#endif

#ifdef END_CLOUDY_FOG
#include "/lib/atmosphere/volumetricClouds.glsl"
#endif

#include "/lib/atmosphere/skyEffects.glsl"

#ifdef OVERWORLD
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/sunMoon.glsl"
#endif

#include "/lib/atmosphere/fog.glsl"

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	float z1 = texture2D(depthtex1, texCoord).r;

	#ifdef DISTANT_HORIZONS
	float dhZ = texture2D(dhDepthTex0, texCoord).r;
	#endif

	vec3 viewPos = ToView(vec3(texCoord, z1));
	vec3 worldPos = ToWorld(viewPos);

    //Atmosphere Variables
	#if defined OVERWORLD
	vec3 sunPos = vec3(gbufferModelViewInverse * vec4(sunVec * 128.0, 1.0));
	vec3 sunCoord = sunPos / (sunPos.y + length(sunPos.xz));
    vec3 atmosphereColor = getAtmosphericScattering(viewPos, normalize(sunCoord));
	#elif defined NETHER
	vec3 atmosphereColor = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 atmosphereColor = endLightCol * 0.1;
	#endif

    vec3 skyColor = atmosphereColor;

	#if defined OVERWORLD || defined END
	vec3 nViewPos = normalize(viewPos);

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

	#if defined VC || defined END_CLOUDY_FOG
	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif
	#endif
	
	#ifdef VC
	computeVolumetricClouds(vc, skyColor, z1, blueNoiseDither, cloudDepth);
	#endif

	#ifdef END_CLOUDY_FOG
	computeEndVolumetricClouds(vc, skyColor, z1, blueNoiseDither, cloudDepth);
	#endif

	//Atmosphere Calculations
	float nebulaFactor = 0.0;

	#ifdef END_NEBULA
	getEndNebula(skyColor, atmosphereColor, worldPos, VoU, nebulaFactor, 1.0);
	#endif

	vec3 stars = vec3(0.0);
	float pc = 0.0;

	#ifdef OVERWORLD
	if (VoU > 0.0) {
		#ifdef PLANAR_CLOUDS
		drawPlanarClouds(skyColor, atmosphereColor, worldPos, viewPos, VoU, caveFactor, vc.a, pc);
		#endif

		float cloudBlockFactor = min(vc.a + pow(pc, 0.33), 1.0);

		#ifdef MILKY_WAY
		drawMilkyWay(skyColor, worldPos, VoU, caveFactor, nebulaFactor, cloudBlockFactor);
		#endif

		#ifdef AURORA
		drawAurora(skyColor, worldPos, VoU, caveFactor);
		#endif

		#ifdef STARS
		drawStars(skyColor, worldPos, sunVec, stars, VoU, VoS, caveFactor, nebulaFactor, cloudBlockFactor, 0.5);
		#endif

		#ifdef RAINBOW
		getRainbow(skyColor, worldPos, VoU, 1.75, 0.05, caveFactor);
		#endif
	}

	getSunMoon(skyColor, nViewPos, worldPos, lightSun, lightNight, VoS, VoM, VoU, caveFactor, (1.0 - pow(vc.a, 0.25)) * (1.0 - pow(pc, 0.25)));
	#endif

	#ifdef END
	#ifdef END_STARS
	drawStars(skyColor, worldPos, sunVec, stars, VoU, VoS, 1.0, nebulaFactor, vc.a, 0.6);
	#endif

	#ifdef END_VORTEX
	getEndVortex(skyColor, worldPos, stars, VoU, VoS);
	#endif
	#endif

	skyColor *= 1.0 + (Bayer8(gl_FragCoord.xy) - 0.5) / 64.0;

	#if MC_VERSION >= 11900
	skyColor *= 1.0 - darknessFactor;
	#endif

	skyColor *= 1.0 - blindFactor;

	#ifndef DISTANT_HORIZONS
	if (z1 == 1.0) color = skyColor;
	#else
	if (dhZ == 1.0 && z1 == 1.0) color = skyColor;
	#endif

	//Fog Calculations
	#ifdef DISTANT_HORIZONS
	if (z1 != 1.0) {
		Fog(color, viewPos, worldPos, atmosphereColor);
	} else if (dhZ != 1.0) {
		vec4 dhScreenPos = vec4(texCoord, dhZ, 1.0);
		vec4 dhViewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
			 dhViewPos /= dhViewPos.w;
		
		Fog(color, dhViewPos.xyz, ToWorld(dhViewPos.xyz), atmosphereColor);
	}
	#else
	Fog(color, viewPos, worldPos, atmosphereColor);
	#endif

	//Volumetric Clouds
	#if defined VC || defined END_CLOUDY_FOG
	vc.rgb = pow(vc.rgb, vec3(1.0 / 2.2));

	#ifdef DISTANT_HORIZONS
	cloudDepth /= (2.0 * dhFarPlane);
	#else
	cloudDepth /= (2.0 * far);
	#endif

	color = mix(color, vc.rgb, vc.a);
	#endif

	/* DRAWBUFFERS:064 */
	gl_FragData[0].rgb = color;
    gl_FragData[1].rgb = pow(color / 256.0, vec3(0.125));
	gl_FragData[2].g = cloudDepth;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

#if defined OVERWORLD || defined END
out vec3 sunVec, upVec;
#endif

//Uniforms
#if defined OVERWORLD || defined END
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Program//
void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Sun & Other vectors
    #if defined OVERWORLD || defined END
	getSunVector(gbufferModelView, timeAngle, sunVec);
	upVec = normalize(gbufferModelView[1].xyz);
	#endif

	//Position
	gl_Position = ftransform();

	#if SOLAS_BY_SEPTONIOUS != 1
	texCoord.y *= 0.4;
	#endif
}

#endif