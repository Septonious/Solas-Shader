#define GBUFFERS_BLOCK

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;
in vec2 lmCoord;
in vec3 normal;
in vec3 eastVec, northVec, sunVec, upVec;
in vec4 color;

//Uniforms//
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef DYNAMIC_HANDLIGHT
uniform int heldItemId, heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
#endif
uniform int blockEntityId;

#ifdef AURORA
uniform int moonPhase;
uniform float isSnowy;
#endif

uniform float viewWidth, viewHeight;
uniform float blindFactor;
uniform float nightVision;
uniform float frameTimeCounter;

#ifdef OVERWORLD
uniform float timeBrightness, timeAngle;
uniform float shadowFade;
uniform float wetness;
#endif

uniform ivec2 eyeBrightnessSmooth;
uniform vec3 cameraPosition;
uniform vec3 skyColor;
uniform vec3 fogColor;

uniform sampler2D texture;
uniform sampler2D noisetex;

uniform sampler3D floodfillSampler;
uniform usampler3D voxelSampler;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

//Common Variables//
#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
vec3 lightVec = sunVec;
#endif

const vec3[8] endPortalColors = vec3[8](
    vec3(0.35, 0.60, 0.75) * 1.50,
    vec3(0.60, 0.70, 1.00) * 1.40,
    vec3(0.45, 0.80, 0.90) * 1.30,
    vec3(0.35, 1.00, 1.85) * 1.20,
    vec3(0.75, 0.85, 0.65) * 1.10,
    vec3(0.40, 0.55, 0.80) * 1.00,
    vec3(0.50, 0.65, 1.00) * 0.90,
    vec3(0.55, 0.55, 0.80) * 0.80
);

//Includes//
#include "/lib/util/transformMacros.glsl"
#include "/lib/util/encode.glsl"
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/util/bayerDithering.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/color/netherColor.glsl"
#include "/lib/vx/blocklightColor.glsl"
#include "/lib/vx/voxelization.glsl"
#include "/lib/pbr/ggx.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/gbuffersLighting.glsl"

#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;

	vec3 newNormal = normal;
	float emission = 0.0;

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	#ifdef TAA
	vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
	#else
	vec3 viewPos = ToNDC(screenPos);
	#endif
	vec3 worldPos = ToWorld(viewPos);
	vec2 lightmap = clamp(lmCoord, 0.0, 1.0);

	float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
	float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
	float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

	vec3 shadow = vec3(0.0);

    if (blockEntityId == 10303) {
		vec2 portalCoordPlayerPos = screenPos.xy;

		float portalNoise = texture2D(noisetex, portalCoordPlayerPos * 0.25).r * 0.25 + 0.375;
		float portal0 = texture2D(texture, portalCoordPlayerPos.rg * 0.50 + vec2(0.0, frameTimeCounter * 0.012)).r * 3.00;
		float portal1 = texture2D(texture, portalCoordPlayerPos.gr * 0.75 + vec2(0.0, frameTimeCounter * 0.009)).r * 2.50;
		float portal2 = texture2D(texture, portalCoordPlayerPos.rg * 1.00 + vec2(0.0, frameTimeCounter * 0.006)).r * 1.75;
		float portal3 = texture2D(texture, portalCoordPlayerPos.gr * 1.25 + vec2(0.0, frameTimeCounter * 0.003)).r * 1.25;
		
		albedo.rgb = pow2(portalNoise) * endAmbientCol + portal3 * vec3(0.3, 0.2, 0.5) + portal2 * vec3(0.4, 0.2, 0.4) + portal1 * vec3(0.2, 0.4, 0.4) + portal0 * vec3(0.2, 0.3, 0.5);
		emission = length(albedo.rgb) * 8.0;
    } else {
        gbuffersLighting(albedo, screenPos, viewPos, worldPos, shadow, lightmap, NoU, NoL, NoE, 0.0, 0.0, emission, 0.0);
    }

	/* DRAWBUFFERS:03 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(encodeNormal(newNormal), emission * 0.1, 1.0);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;
out vec2 lmCoord;
out vec3 normal;
out vec3 eastVec, northVec, sunVec, upVec;
out vec4 color;

//Uniforms//
#ifdef TAA
uniform float viewWidth, viewHeight;
#endif

#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

uniform mat4 gbufferModelView, gbufferModelViewInverse;

//Includes
#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Lightmap Coord
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Normal
	normal = normalize(gl_NormalMatrix * gl_Normal);

	//Sun & Other vectors
	#if defined OVERWORLD || defined END
	sunVec = getSunVector(gbufferModelView, timeAngle);
	#endif
	
	upVec = normalize(gbufferModelView[1].xyz);
	northVec = normalize(gbufferModelView[2].xyz);
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