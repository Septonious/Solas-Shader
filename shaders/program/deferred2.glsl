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

#ifdef OVERWORLD
uniform int moonPhase;

uniform float timeBrightness, timeAngle, rainStrength;
#endif

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform float blindFactor;
uniform float viewWidth, viewHeight;
uniform float far, frameTimeCounter;

#ifdef VC
uniform float shadowFade;
#endif

#if (defined AURORA && defined AURORA_COLD_BIOME_VISIBILITY) || defined RAINBOW
uniform float isSnowy;
#endif

#ifdef RAINBOW
uniform float wetness;
#endif

#ifdef OVERWORLD
uniform ivec2 eyeBrightnessSmooth;

uniform vec3 skyColor;
#endif

uniform vec3 cameraPosition;

uniform sampler2D colortex0;
uniform sampler2D depthtex1;

#if defined END_NEBULA || defined AURORA || defined VC
uniform sampler2D noisetex;
#endif

#ifdef MILKY_WAY
uniform sampler2D depthtex2;
#endif

uniform sampler2D colortex2;

#ifdef VC
uniform sampler2D shadowcolor1;
uniform sampler2DShadow shadowtex0, shadowtex1;

uniform mat4 shadowProjection, shadowModelView;
#endif

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;

#ifdef OVERWORLD
uniform mat4 gbufferModelView;
#endif

//Common Variables//
#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, eBS);
float sunVisibility = clamp(dot(sunVec, upVec) + 0.025, 0.0, 0.1) * 10.0;
#endif

//Includes//
#include "/lib/color/dimensionColor.glsl"
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"

#ifdef VC
#include "/lib/util/blueNoiseDithering.glsl"
#include "/lib/atmosphere/spaceConversion.glsl"
#include "/lib/atmosphere/volumetricClouds.glsl"
#endif

#ifdef OVERWORLD
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/sunMoon.glsl"
#endif

#if defined OVERWORLD || defined END
#include "/lib/atmosphere/skyEffects.glsl"
#endif

#include "/lib/atmosphere/fog.glsl"

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;
	vec4 colortex2Data = texture2D(colortex2, texCoord);

	float cloudDepth = 0.0;
	float z1 = texture2D(depthtex1, texCoord).r;
	vec3 viewPos = ToView(vec3(texCoord, z1));
	vec3 worldPos = ToWorld(viewPos);

	#if defined OVERWORLD
	vec3 atmosphereColor = getAtmosphere(viewPos);
	#elif defined NETHER
	vec3 atmosphereColor = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 atmosphereColor = endLightCol * 0.15;
	#endif

    vec3 skyColor = atmosphereColor;

	#if defined OVERWORLD || defined END
	float nebulaFactor = 0.0;
	float sunMoon = 0.0;
	float star = 0.0;

	vec3 nViewPos = normalize(viewPos);
	float VoU = dot(nViewPos, upVec);
	float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
	float VoM = clamp(dot(nViewPos, -sunVec), 0.0, 1.0);
	#endif

	#ifdef VC
	vec4 vc = vec4(0.0);

	float blueNoiseDither = getBlueNoise(gl_FragCoord.xy);

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + frameTimeCounter * 16.0);
	#endif

	computeVolumetricClouds(vc, atmosphereColor, z1, blueNoiseDither, cloudDepth);
	#endif

	if (z1 == 1.0) { //Sky rendering
		#ifdef OVERWORLD
		if (caveFactor != 0.0 && VoU > 0.0) {
			VoU = pow2(VoU);

			#ifdef MILKY_WAY
			getNebula(skyColor, worldPos, VoU, nebulaFactor, caveFactor);
			#endif

			#ifdef STARS
			getStars(skyColor, worldPos, VoU, nebulaFactor, clamp(caveFactor - cloudDepth, 0.0, 1.0), star);
			#endif

			#ifdef RAINBOW
			getRainbow(skyColor, worldPos, VoU, 1.75, 0.05, caveFactor);
			#endif

			#ifdef AURORA
			getAurora(skyColor, worldPos, caveFactor);
			#endif
		}

		getSunMoon(skyColor, nViewPos, lightSun * (1.0 - cloudDepth), lightNight * (1.0 - cloudDepth), VoS, VoM, caveFactor, sunMoon);
		#endif

		#ifdef END
		#ifdef END_NEBULA
		getNebula(skyColor, worldPos, VoU, nebulaFactor, 1.0);
		#endif

		#ifdef END_STARS
		getStars(skyColor, worldPos, VoU, nebulaFactor, 1.0, star);
		#endif

		#ifdef END_VORTEX
		getEndVortex(skyColor, worldPos, VoU, VoS);
		#endif
		#endif

		#if MC_VERSION >= 11900
		skyColor *= 1.0 - darknessFactor;
		#endif

		skyColor *= 1.0 - blindFactor;

		#ifdef TAA
		skyColor += fract(Bayer64(gl_FragCoord.xy) + frameTimeCounter * 16.0 - 0.5) / 64.0;
		#endif

		color = skyColor;
	} else {
		Fog(color, viewPos, worldPos, skyColor);
	}

	#ifdef VC
	color = mix(color, pow(vc.rgb, vec3(1.0 / 2.2)), vc.a * vc.a * mix(VC_OPACITY, 0.4, rainStrength));
	#endif

	#ifdef INTEGRATED_SPECULAR
	vec3 reflectionColor = pow(color.rgb, vec3(0.125)) * 0.5;
	#endif

	#ifdef BLOOM
	#ifdef OVERWORLD
	colortex2Data.ba += vec2(sunMoon * 0.125, sunMoon);
	#elif defined END
	colortex2Data.ba += vec2(star);
	#endif
	#endif

	/* DRAWBUFFERS:042 */
	gl_FragData[0].rgb = color;
	gl_FragData[1].a = cloudDepth;
	gl_FragData[2] = colortex2Data;

	#ifdef INTEGRATED_SPECULAR
	/* DRAWBUFFERS:0426 */
	gl_FragData[3] = vec4(reflectionColor, float(z1 < 1.0));
	#endif
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
    #if defined OVERWORLD
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * PI) * -0.5 + 0.5 - ang) / 3.0) * TAU;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
    #elif defined END
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
    sunVec = normalize((gbufferModelView * vec4(vec3(0.0, sunRotationData * 2000.0), 1.0)).xyz);
    #endif

	#if defined OVERWORLD || defined END
	upVec = normalize(gbufferModelView[1].xyz);
	#endif

	//Position
	gl_Position = ftransform();
}

#endif