#define GBUFFERS_TEXTURED

#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec4 color;
in vec3 normal;
in vec2 texCoord, lmCoord;

// Uniforms //
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef AURORA_LIGHTING_INFLUENCE
uniform int moonPhase;
#endif

#ifdef VC_SHADOWS
uniform int worldDay, worldTime;
#endif

uniform float frameTimeCounter;
uniform float far, near;
uniform float viewWidth, viewHeight;
uniform float blindFactor, nightVision;
#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

#ifdef OVERWORLD
uniform float wetness;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;

#if MC_VERSION >= 12104
uniform float isPaleGarden;
#endif

uniform vec3 skyColor;
#endif

#ifdef GENERATED_EMISSION
uniform ivec2 atlasSize;
#endif

uniform ivec2 eyeBrightnessSmooth;
uniform vec3 cameraPosition;

#ifdef NETHER
uniform vec3 fogColor;
#endif

uniform vec4 lightningBoltPosition;

uniform sampler2D texture, noisetex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

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
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, sqrt(eBS));
float sunVisibility = clamp((dot( sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#endif

// Includes //
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/transformMacros.glsl"
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/lighting/lightning.glsl"
#include "/lib/lighting/shadows.glsl"

#ifdef VC_SHADOWS
#include "/lib/lighting/cloudShadows.glsl"
#endif

#ifdef DYNAMIC_HANDLIGHT
#include "/lib/vx/blocklightColor.glsl"
#include "/lib/lighting/handlight.glsl"
#endif

#include "/lib/lighting/gbuffersLighting.glsl"

#ifdef OVERWORLD
#include "/lib/atmosphere/sky.glsl"
#endif

#include "/lib/atmosphere/fog.glsl"

// Main //
void main() {
	vec4 albedoTexture = texture2D(texture, texCoord);

	vec4 albedo = albedoTexture * color;
		 albedo.a *= albedo.a;



    vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));
    vec3 newNormal = normal;
    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    vec3 viewPos = ToNDC(screenPos);
    vec3 worldPos = ToWorld(viewPos);

	float subsurface = 0.0;
    float emission = 0.0;

	float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
    #if defined OVERWORLD
	float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
    #elif defined END
    float NoL = clamp(dot(newNormal, sunVec), 0.0, 1.0);
    #else
    float NoL = 0.0;
    #endif
	float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

	//iPBR Generated Emission
	#ifdef GENERATED_EMISSION
	if (atlasSize.x < 900.0) { // We don't want to detect particles from the block atlas
		float lAlbedo = length(albedo.rgb);
		vec3 gamePos = worldPos + cameraPosition;

		if (color.a < 1.01 && lAlbedo < 1.0) // Campfire Smoke, World Border
			albedo.a *= 0.6;
		else if (albedoTexture.r > 0.99) {
			emission = max(pow4(albedo.r), 0.1) * pow4(lightmap.x);
		}

		if (max(abs(albedoTexture.r - albedoTexture.b), abs(albedoTexture.b - albedoTexture.g)) < 0.001) { // Grayscale Particles
			if (lAlbedo > 0.3 && color.g < 0.5 && color.b > color.r * 1.1 && color.r > 0.3) // Ender Particle, Crying Obsidian Drop
				emission = max(pow4(albedo.r), 0.1) * 4.0;
			if (lAlbedo > 0.3 && color.g < 0.5 && color.r > (color.g + color.b) * 3.0) // Redstone Particle
				lightmap = vec2(0.0), emission = max(pow4(albedo.r), 0.1);
		}
	}
	#endif

    vec3 shadow = vec3(0.0);
    gbuffersLighting(albedo, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, subsurface, emission, 0.0, 0.0);

    //Fog
    #if defined OVERWORLD
    vec3 atmosphereColor = getAtmosphere(viewPos);
	#elif defined NETHER
	vec3 atmosphereColor = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 atmosphereColor = endAmbientColSqrt * 0.25;
	#endif

    Fog(albedo.rgb, viewPos, worldPos, atmosphereColor, 0.0);

	/* DRAWBUFFERS:01 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
}

#endif


//**//**//**//**//**//**//**//**//**//**//**//**//**//**//


#ifdef VSH

// VSH Data //
out vec4 color;
out vec3 normal;
out vec2 texCoord, lmCoord;

// Attributes //
attribute vec4 mc_Entity;

// Main //
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));
	
    color = gl_Color;

    normal = normalize(gl_NormalMatrix * gl_Normal);

	gl_Position = ftransform();
}

#endif