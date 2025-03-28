#define GBUFFERS_TEXTURED

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec4 color;
in vec3 normal;
in vec3 eastVec, sunVec, upVec;
in vec2 texCoord, lmCoord;

//Uniforms//
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef DISTANT_HORIZONS
uniform int dhRenderDistance;
#endif

#ifdef DYNAMIC_HANDLIGHT
uniform int heldItemId, heldItemId2;
#endif

uniform float far, near;
uniform float viewWidth, viewHeight;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

#if MC_VERSION >= 12104
uniform float isPaleGarden;
#endif

uniform float blindFactor;
uniform float nightVision;

#ifdef OVERWORLD
uniform float timeBrightness, timeAngle;
uniform float shadowFade;
uniform float wetness;

#ifdef AURORA
uniform int moonPhase;
uniform float isSnowy;
#endif

uniform ivec2 eyeBrightnessSmooth;
#endif

#ifdef GENERATED_EMISSION
uniform ivec2 atlasSize;
#endif

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec3 cameraPosition;

uniform sampler2D texture;
uniform sampler2D noisetex;

#ifdef VC
uniform sampler2D gaux1;
#endif

uniform sampler3D floodfillSampler, floodfillSamplerCopy;
uniform usampler3D voxelSampler;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

//Common Variables//
#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, eBS);
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
vec3 lightVec = sunVec;
#endif

//Includes//
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/color/netherColor.glsl"
#include "/lib/vx/blocklightColor.glsl"
#include "/lib/vx/voxelization.glsl"

#ifdef DYNAMIC_HANDLIGHT
#include "/lib/lighting/handlight.glsl"
#endif

#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/gbuffersLighting.glsl"

#ifdef OVERWORLD
#include "/lib/atmosphere/sky.glsl"
#endif

#include "/lib/atmosphere/fog.glsl"

//Program//
void main() {
	vec4 albedoTexture = texture2D(texture, texCoord);
	if (albedoTexture.a <= 0.00001) discard;
	vec4 albedo = albedoTexture * color;
		 albedo.a *= albedo.a;
	vec3 newNormal = normal;
	float cloudBlendOpacity = 1.0;
	float emission = 0.0;

	if (albedo.r < 0.29 && albedo.g < 0.45 && albedo.b > 0.75) discard;

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	vec3 viewPos = ToNDC(screenPos);
	vec3 worldPos = ToWorld(viewPos);
	vec2 lightmap = clamp(lmCoord, 0.0, 1.0);

	//Volumetric Clouds Blending
	#ifdef VC
	float cloudDepth = texture2D(gaux1, screenPos.xy).g * (far * 2.0);
	cloudBlendOpacity = step(length(viewPos), cloudDepth);

	if (cloudBlendOpacity == 0) {
		discard;
	}
	#endif

	float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
	float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
	float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

	//iPBR Generated Emission
	#ifdef GENERATED_EMISSION
	if (atlasSize.x < 900.0) { // We don't want to detect particles from the block atlas
		float lAlbedo = length(albedo.rgb);
		vec3 gamePos = worldPos + cameraPosition;

		if (color.a < 1.01 && lAlbedo < 1.0) // Campfire Smoke, World Border
			albedo.a *= 0.4;
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
	gbuffersLighting(albedo, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, 0.1, 0.0, emission, 0.0);

	//Fog & Atmosphere Calculations
	#if defined OVERWORLD
	vec3 sunPos = vec3(gbufferModelViewInverse * vec4(sunVec * 128.0, 1.0));
	vec3 sunCoord = sunPos / (sunPos.y + length(sunPos.xz));
    vec3 atmosphereColor = getAtmosphericScattering(viewPos, normalize(sunCoord));
	#elif defined NETHER
	vec3 atmosphereColor = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 atmosphereColor = endLightCol * 0.1;
	#endif

	Fog(albedo.rgb, viewPos, worldPos, atmosphereColor);
	albedo.a *= cloudBlendOpacity;

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec4 color;
out vec3 normal;
out vec3 eastVec, sunVec, upVec;
out vec2 texCoord, lmCoord;

//Uniforms//
#ifdef TAA
uniform float viewWidth, viewHeight;
#endif

uniform float timeAngle;

uniform mat4 gbufferModelView, gbufferModelViewInverse;

//Includes//
#ifdef TAA
#include "/lib/antialiasing/jitter.glsl"
#endif

//Program//
void main() {
	//Coord
	texCoord = mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.xy + gl_TextureMatrix[0][3].xy;

	//Lightmap Coord
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Normal
	normal = normalize(gl_NormalMatrix * gl_Normal);

	//Sun & Other vectors
	getSunVector(gbufferModelView, timeAngle, sunVec);
	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

	//Color & Position
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	color = gl_Color;
	if (color.a < 0.1) color.a = 1.0;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

	#ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif