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

#ifdef OVERWORLD
uniform int moonPhase;

uniform float timeBrightness, timeAngle, rainStrength, wetness;
uniform float isSnowy;
#endif

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform float far, near;
uniform float blindFactor;
uniform float frameTimeCounter;
uniform float viewWidth, viewHeight;
uniform float shadowFade;

#ifdef OVERWORLD
uniform ivec2 eyeBrightnessSmooth;

uniform vec3 skyColor;
#endif

uniform vec3 fogColor;
uniform vec3 cameraPosition;

#ifdef MILKY_WAY
uniform sampler2D depthtex2;
#endif

#ifdef SKYBOX
uniform sampler2D colortex7;
#endif

uniform sampler2D noisetex;
uniform sampler2D colortex0;
uniform sampler2D depthtex1;

#if defined VC || defined END_CLOUDY_FOG
uniform sampler2D shadowtex1;

#ifdef BLOCKY_CLOUDS
uniform sampler2D shadowcolor1;
#endif

uniform mat4 shadowModelView, shadowProjection;
#endif

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;

#ifdef OVERWORLD
uniform mat4 gbufferModelView;
#endif

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

#ifdef OVERWORLD
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/sunMoon.glsl"
#endif

#if defined VC || defined END_CLOUDY_FOG
#include "/lib/atmosphere/spaceConversion.glsl"
#include "/lib/util/ToShadow.glsl"
#endif

#ifdef VC
#ifndef BLOCKY_CLOUDS
#include "/lib/atmosphere/volumetricClouds.glsl"
#else
#include "/lib/atmosphere/volumetricBlockyClouds.glsl"
#endif
#endif

#ifdef END_CLOUDY_FOG
#include "/lib/atmosphere/volumetricClouds.glsl"
#endif

#include "/lib/atmosphere/skyEffects.glsl"
#include "/lib/atmosphere/fog.glsl"

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	float z1 = texture2D(depthtex1, texCoord).r;
	vec3 viewPos = ToView(vec3(texCoord, z1));
	vec3 worldPos = ToWorld(viewPos);

    //Atmosphere
	#if defined OVERWORLD
	vec3 sunPos = vec3(gbufferModelViewInverse * vec4(sunVec * 128.0, 1.0));
	vec3 sunCoord = sunPos / (sunPos.y + length(sunPos.xz));
    vec3 atmosphereColor = getAtmosphericScattering(normalize(worldPos) * PI, viewPos, normalize(sunCoord));

	#ifdef SKYBOX
	vec3 skybox = texture2D(colortex7, texCoord).rgb;
	atmosphereColor = mix(atmosphereColor, skybox, SKYBOX_MIX_FACTOR);
	#endif
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

    //Volumetric clouds
	vec4 vc = vec4(0.0);

	float cloudDepth = 2.0 * far;
	
	#ifdef VC
	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif

	computeVolumetricClouds(vc, atmosphereColor, z1, blueNoiseDither, cloudDepth);
	vc.rgb = pow(vc.rgb, vec3(1.0 / 2.2));
	#endif

	#ifdef END_CLOUDY_FOG
	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif

	computeEndVolumetricClouds(vc, atmosphereColor, z1, blueNoiseDither, cloudDepth);
	vc.rgb = pow(vc.rgb, vec3(1.0 / 2.2));
	#endif

	//Atmosphere & Fog
	float nebulaFactor = 0.0;

	#ifdef END_NEBULA
	getEndNebula(skyColor, worldPos, VoU, nebulaFactor, 1.0);
	#endif

	if (z1 == 1.0) { //Sky rendering
		vec3 stars = vec3(0.0);
		float pc = 0.0;

		#ifdef OVERWORLD
		if (VoU > 0.0) {
			#ifdef MILKY_WAY
			drawMilkyWay(skyColor, worldPos, VoU, caveFactor, nebulaFactor, vc.a * 2.0);
			#endif

			#ifdef AURORA
			drawAurora(skyColor, worldPos, VoU, caveFactor, vc.a);
			#endif

			#ifdef PLANAR_CLOUDS
			drawPlanarClouds(skyColor, atmosphereColor, worldPos, viewPos, VoU, caveFactor, vc.a, pc);
			#endif

			#ifdef STARS
			drawStars(skyColor, worldPos, stars, VoU, caveFactor, nebulaFactor, min(vc.a * 2.0 + pow(pc, 0.25), 1.0), 0.4);
			#endif

			#ifdef RAINBOW
			getRainbow(skyColor, worldPos, VoU, 1.75, 0.05, caveFactor);
			#endif
		}

		getSunMoon(skyColor, nViewPos, worldPos, lightSun, lightNight, VoS, VoM, VoU, caveFactor * (1.0 - vc.a) * (1.0 - pc));
		#endif

		#ifdef END
		#ifdef END_STARS
		drawStars(skyColor, worldPos, stars, VoU, 1.0, nebulaFactor, vc.a, 0.3);
		#endif

		#ifdef END_VORTEX
		getEndVortex(skyColor, worldPos, stars, VoU, VoS);
		#endif
		#endif

		skyColor *= 1.0 + (Bayer8(gl_FragCoord.xy) - 0.5) / 32.0;

		color = skyColor;

		#if MC_VERSION >= 11900
		color *= 1.0 - darknessFactor;
		#endif

		color *= 1.0 - blindFactor;
	} 
	
	#if MC_VERSION >= 11900
	skyColor *= 1.0 - darknessFactor;
	#endif

	skyColor *= 1.0 - blindFactor;

	if (z1 != 1.0) Fog(color, viewPos, worldPos, skyColor);

	#if defined VC || defined END_CLOUDY_FOG
	color = mix(color, vc.rgb, vc.a);
	#endif

	/* DRAWBUFFERS:064 */
	gl_FragData[0].rgb = color;
    gl_FragData[1] = vec4(pow(color.rgb, vec3(0.125)) * 0.5, 1.0);
	gl_FragData[2].g = cloudDepth / (2.0 * far);
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

void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Sun & Other vectors
    #if defined OVERWORLD || defined END
	sunVec = getSunVector(gbufferModelView, timeAngle);
	upVec = normalize(gbufferModelView[1].xyz);
	#endif

	//Position
	gl_Position = ftransform();
}

#endif