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

#if (defined VC || defined AURORA) && defined TAA
uniform int frameCounter;
#endif

uniform float timeBrightness, timeAngle, rainStrength, wetness;
#endif

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform float far, near;
uniform float blindFactor;
uniform float frameTimeCounter;
uniform float viewWidth, viewHeight;

#ifdef VC
uniform float shadowFade;
uniform int worldDay;
#endif

#if (defined AURORA && defined AURORA_COLD_BIOME_VISIBILITY) || defined RAINBOW
uniform float isSnowy;
#endif

#ifdef OVERWORLD
uniform ivec2 eyeBrightnessSmooth;

uniform vec3 skyColor, fogColor;
#endif

uniform vec3 cameraPosition;

#if defined END_NEBULA || defined AURORA || defined VC
uniform sampler2D noisetex;
#endif

uniform sampler2D colortex0;
uniform sampler2D depthtex1;

#ifdef MILKY_WAY
uniform sampler2D depthtex2;
#endif

#ifdef VC
uniform sampler2D shadowtex1;

#ifdef BLOCKY_CLOUDS
uniform sampler2D shadowcolor1;
#endif

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
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/color/dimensionColor.glsl"

#ifdef VC
#include "/lib/atmosphere/spaceConversion.glsl"
#include "/lib/util/ToShadow.glsl"
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

	float cloudDepth = 0.0;
	float z1 = texture2D(depthtex1, texCoord).r;
	vec3 viewPos = ToView(vec3(texCoord, z1));
	vec3 worldPos = ToWorld(viewPos);

	#if defined OVERWORLD
	vec3 atmosphereColor = getAtmosphere(viewPos);
	#elif defined NETHER
	vec3 atmosphereColor = netherColSqrt.rgb * 0.5;
	#elif defined END
	vec3 atmosphereColor = endLightCol * 0.15;
	#endif

    vec3 skyColor = atmosphereColor;

	#if defined OVERWORLD || defined END
	float nebulaFactor = 0.0;
	float sunMoon = 0.0;

	vec3 nViewPos = normalize(viewPos);
	float VoU = dot(nViewPos, upVec);
	float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
	float VoM = clamp(dot(nViewPos, -sunVec), 0.0, 1.0);
	#endif

	#if defined VC || defined AURORA
	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + frameCounter * 0.618);
	#endif
	#endif

	#ifdef VC
	vec4 vc = vec4(0.0);

	computeVolumetricClouds(vc, atmosphereColor, z1, blueNoiseDither, cloudDepth);
	vc.rgb = pow(vc.rgb, vec3(1.0 / 2.2));
	#endif

	if (z1 == 1.0) { //Sky rendering
		#ifdef OVERWORLD
		if (caveFactor != 0.0 && VoU > 0.0) {
			VoU = pow2(VoU);

			#ifdef MILKY_WAY
			getNebula(skyColor, worldPos, VoU, nebulaFactor, caveFactor);
			#endif

			#ifdef STARS
			getStars(skyColor, worldPos, VoU, nebulaFactor, clamp(caveFactor - cloudDepth, 0.0, 1.0));
			#endif

			#ifdef RAINBOW
			getRainbow(skyColor, worldPos, VoU, 1.75, 0.05, caveFactor);
			#endif

			#ifdef AURORA
			getAurora(skyColor, worldPos, caveFactor, blueNoiseDither);
			#endif
		}

		getSunMoon(skyColor, nViewPos, lightSun * (1.0 - cloudDepth), lightNight * (1.0 - cloudDepth), VoS, VoM, caveFactor, sunMoon);
		#endif

		#ifdef END
		#ifdef END_NEBULA
		getNebula(skyColor, worldPos, VoU, nebulaFactor, 1.0);
		#endif

		#ifdef END_STARS
		getStars(skyColor, worldPos, VoU, nebulaFactor, 1.0);
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
	} else Fog(color, viewPos, worldPos, skyColor);

	#ifdef VC
	color = mix(color, vc.rgb, vc.a);
	#endif

	vec3 reflectionColor = pow(color.rgb, vec3(0.125)) * 0.5;

	/* DRAWBUFFERS:067 */
	gl_FragData[0].rgb = color;
	gl_FragData[1].rgb = reflectionColor;
	gl_FragData[2].a = float(cloudDepth > 0.0);
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