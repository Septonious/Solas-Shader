#define DH_WATER
#define GBUFFERS_WATER

#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec4 color;
in vec3 normal, binormal, tangent;
in vec2 texCoord, lmCoord;

#if WATER_NORMALS > 0
in vec3 viewVector;
in float viewDistance;
#endif

flat in int mat;

// Uniforms //
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef AURORA_LIGHTING_INFLUENCE
uniform int moonPhase;
#endif

uniform int dhRenderDistance;

uniform int worldDay, worldTime;

uniform float frameTimeCounter;
uniform float far, near;
uniform float dhFarPlane;
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

uniform vec3 fogColor;

uniform ivec2 eyeBrightnessSmooth;
uniform vec3 cameraPosition;
uniform vec4 lightningBoltPosition;

uniform sampler2D texture, noisetex;
uniform sampler2D depthtex1;
uniform sampler2D dhDepthTex1;
uniform sampler2D gaux1;

#ifdef VOLUMETRIC_CLOUDS
uniform sampler2D gaux2;
#endif

uniform mat4 dhProjection;
uniform mat4 dhProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

// Global Variables //
mat4 gbufferProjection = dhProjection;
mat4 gbufferProjectionInverse = dhProjectionInverse;

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
#include "/lib/util/transformMacros.glsl"
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToScreen.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/pbr/ggx.glsl"
#include "/lib/lighting/lightning.glsl"
#include "/lib/lighting/shadows.glsl"

#ifdef VC_SHADOWS
#include "/lib/lighting/cloudShadows.glsl"
#endif

#include "/lib/lighting/gbuffersLighting.glsl"
#include "/lib/water/waterFog.glsl"

#ifdef OVERWORLD
#include "/lib/atmosphere/sky.glsl"
#endif

#include "/lib/atmosphere/fog.glsl"

#if WATER_NORMALS > 0
#include "/lib/water/waterNormals.glsl"
#endif

#ifdef WATER_REFLECTIONS
#include "/lib/pbr/raytracer.glsl"
#include "/lib/pbr/waterReflection.glsl"
#endif

//Program//
void main() {
	vec4 albedo = color;
	if (albedo.a <= 0.00001) discard;

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);

	float opaqueDepth = texture2D(depthtex1, screenPos.xy).r;
	if (opaqueDepth < 1.0) {
		discard;
		return;
	}

    vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));
    vec3 newNormal = normal;
    vec3 viewPos = ToNDC(screenPos);
    vec3 worldPos = ToWorld(viewPos);
	vec3 nViewPos = normalize(viewPos);
	vec2 refraction = vec2(0.0);

	float water = float(mat == 10001);
	float glass = 1.0 - water;
    float emission = pow8(lmCoord.x);

	if (water > 0.5) {
		#ifdef VANILLA_WATER
		albedo.a = WATER_A;
		#else
		//Water Light Absorption & Scattering
		vec4 waterFog = vec4(0.0);

		float oDepth = texture2D(dhDepthTex1, screenPos.xy).r;
		vec3 oScreenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), oDepth);
		vec3 oViewPos = ToNDC(oScreenPos);

		vec3 colorMult = vec3(1.0);
		waterFog = getWaterFog(colorMult, viewPos - oViewPos);

		albedo.rgb = waterFog.rgb * 3.0;
		albedo.g *= 1.0 + (1.0 - waterFog.a * 0.4); //Correciton
		albedo.a = min(0.1 + 3.0 * WATER_A * waterFog.a * (0.9 - float(isEyeInWater == 1) * 0.7), 1.0);
		#endif
	}

	float dither = Bayer8(gl_FragCoord.xy);
	float viewLength = length(viewPos);
	float minDist = (dither - 1.0) * 16.0 + far;
	if (viewLength < minDist) {
		discard;
	}

	//Volumetric Clouds Blending
	float cloudBlendOpacity = 1.0;

	#ifdef VOLUMETRIC_CLOUDS
	float cloudDepth = texture2D(gaux2, screenPos.xy).r * dhFarPlane;
	cloudBlendOpacity = step(length(viewPos), cloudDepth);

	if (cloudBlendOpacity == 0) {
		discard;
	}
	#endif

	//Water Normals
	float fresnel = clamp(1.0 + dot(normalize(normal), nViewPos), 0.0, 1.0);

	#if WATER_NORMALS > 0
	if (water > 0.5) {
		getWaterNormal(newNormal, worldPos, fresnel);
	}
	#endif

	if (water > 0.5) {
		refraction = (newNormal.xy - normal.xy) * 0.5 + 0.5;	
	} else {
		refraction = newNormal.xy * 0.5 + 0.5;
	}

	float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
    #if defined OVERWORLD
	float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
    #elif defined END
    float NoL = clamp(dot(newNormal, sunVec), 0.0, 1.0);
    #else
    float NoL = 0.0;
    #endif
	float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

    vec3 shadow = vec3(0.0);
    gbuffersLighting(albedo, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, 0.0, emission, 0.6, 0.0);

    #if defined OVERWORLD
    vec3 atmosphereColor = getAtmosphere(viewPos);
	#elif defined NETHER
	vec3 atmosphereColor = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 atmosphereColor = endAmbientColSqrt * 0.25;
	#endif

	//Reflections
	#ifdef WATER_REFLECTIONS
	if (water > 0.5 || glass > 0.5) {
		float snellWindow = clamp(pow4(length(worldPos.xz) * 0.05), 0.05 + float(isEyeInWater == 0) * 0.95, 1.0);
			  snellWindow = max(snellWindow, float(water < 0.5));
		float fresnel = clamp(1.0 + dot(normalize(normal), nViewPos), 0.0, 1.0) * snellWindow;
		getReflection(albedo, viewPos, nViewPos, newNormal, fresnel, lightmap.y);
		albedo.a = fmix(albedo.a * snellWindow, 1.0, fresnel);
	}
	#endif

    //Fog
    Fog(albedo.rgb, viewPos, worldPos, atmosphereColor, 0.0);
	albedo.a *= cloudBlendOpacity;

	/* DRAWBUFFERS:013 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = albedo;
	gl_FragData[2] = vec4(refraction * water, water * 0.4 + 0.4, 1.0);
}

#endif

//**//**//**//**//**//**//**//**//**//**//**//**//**//**//

#ifdef VSH

// VSH Data //
out vec4 color;
out vec3 normal, binormal, tangent;
out vec2 texCoord, lmCoord;

#if WATER_NORMALS > 0
out vec3 viewVector;
out float viewDistance;
#endif

flat out int mat;

// Uniforms //
#ifdef TAA
uniform float viewWidth, viewHeight;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

// Includes //
#ifdef TAA
#include "/lib/antialiasing/jitter.glsl"
#endif

// Main //
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));
	
    color = gl_Color;

	//Normal, Binormal and Tangent
	normal = normalize(gl_NormalMatrix * gl_Normal);
	binormal = normalize(gbufferModelView[2].xyz);
	tangent = normalize(gbufferModelView[0].xyz);

	#if WATER_NORMALS > 0
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
						  tangent.y, binormal.y, normal.y,
						  tangent.z, binormal.z, normal.z);

	viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;
	viewDistance = length(gl_ModelViewMatrix * gl_Vertex);
	#endif

	//Materials
	mat = 0;
	if (dhMaterialId == DH_BLOCK_WATER) {
		mat = 10001;
	}

	//Position
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

	//TAA jittering
    #ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
    #endif
}

#endif