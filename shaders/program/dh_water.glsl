#define DH_WATER
#define GBUFFERS_WATER

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec4 color;
in vec3 normal, binormal, tangent;
in vec3 eastVec, sunVec, upVec;
#if WATER_NORMALS > 0
in vec3 viewVector;
in float viewDistance;
#endif
in vec2 texCoord, lmCoord;
flat in int mat;

//Uniforms//
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef DISTANT_HORIZONS
uniform int dhRenderDistance;
#endif

#ifdef VC_SHADOWS
uniform int worldDay, worldTime;
#endif

uniform float far, near;
uniform float dhFarPlane, dhNearPlane;
uniform float viewWidth, viewHeight;
uniform float frameTimeCounter;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

#if MC_VERSION >= 12104
uniform float isPaleGarden;
#endif

uniform float blindFactor;
uniform float nightVision;

#ifdef AURORA
uniform float isSnowy;
uniform int moonPhase;
#endif

#ifdef OVERWORLD
uniform float timeBrightness, timeAngle;
uniform float shadowFade;
uniform float wetness;

uniform ivec2 eyeBrightnessSmooth;
#endif

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec3 cameraPosition;

uniform sampler2D noisetex;
uniform sampler2D depthtex1;
uniform sampler2D dhDepthTex1;

#ifdef VC
uniform sampler2D gaux1;
#endif

#ifdef WATER_REFLECTIONS
uniform sampler2D gaux3;

#ifdef MILKY_WAY
uniform sampler2D gaux4;
#endif
#endif

uniform mat4 dhProjectionInverse;
uniform mat4 dhProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

//Common Variables//
mat4 gbufferProjection = dhProjection;
mat4 gbufferProjectionInverse = dhProjectionInverse;

#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, eBS);
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
vec3 lightVec = sunVec;
#endif

//Includes//
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/encode.glsl"
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/color/netherColor.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/gbuffersLighting.glsl"

#ifdef TAA
#include "/lib/antialiasing/jitter.glsl"
#endif

#ifdef OVERWORLD
#include "/lib/atmosphere/sky.glsl"
#endif

#ifdef END_NEBULA
#include "/lib/atmosphere/skyEffects.glsl"
#endif

#include "/lib/atmosphere/fog.glsl"

#ifdef WATER_REFLECTIONS
#ifdef OVERWORLD
#include "/lib/atmosphere/stars.glsl"
#include "/lib/atmosphere/milkyWay.glsl"
#endif
#include "/lib/pbr/raytracer.glsl"
#include "/lib/pbr/waterReflection.glsl"
#endif

#ifndef NETHER
#include "/lib/pbr/ggx.glsl"
#endif

#include "/lib/water/waterFog.glsl"

#if WATER_NORMALS > 0
#include "/lib/water/waterNormals.glsl"
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

	vec3 newNormal = normal;
	vec2 refraction = vec2(0.0);
	float emission = pow8(lmCoord.x) + int(mat == 10031) * pow4(length(albedo.rgb)) * 2.0;
	float cloudBlendOpacity = 1.0;

	float water = float(mat == 10001);
	float glass = float(mat >= 10201 && mat <= 10216);

	if (water > 0.5) {
		albedo.rgb = mix(color.rgb, waterColor.rgb, 0.5);
		albedo.a = WATER_A;
	}

	#ifdef TAA
	vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
	#else
	vec3 viewPos = ToNDC(screenPos);
	#endif
	vec3 nViewPos = normalize(viewPos);
	vec3 worldPos = ToWorld(viewPos);
	vec2 lightmap = clamp(lmCoord, 0.0, 1.0);

	float dither = Bayer8(gl_FragCoord.xy);
	float viewLength = length(viewPos);
	float minDist = (dither - 1.0) * 16.0 + far;
	if (viewLength < minDist) {
		discard;
	}

	//Volumetric Clouds Blending
	#ifdef VC
	float cloudDepth = texture2D(gaux1, screenPos.xy).g * (dhFarPlane * 2.0);
	cloudBlendOpacity = step(length(viewPos), cloudDepth);

	if (cloudBlendOpacity == 0) {
		discard;
	}
	#endif

	#if WATER_NORMALS > 0
	if (water > 0.5) {
		float fresnel = clamp(1.0 + dot(normalize(normal), nViewPos), 0.0, 1.0);
		getWaterNormal(newNormal, worldPos, fresnel);
	}
	#endif

	refraction = (newNormal.xy - normal.xy) * 0.5 + 0.5;

	float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
	float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
	float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

    //Reflections
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

	vec3 shadow = vec3(0.0);
	gbuffersLighting(albedo, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, 0.0, 0.0, emission, 0.0);

	if (mat != 10031) {
		if (water > 0.5 && isEyeInWater == 0) {
			#ifdef WATER_FOG
			float oDepth = texture2D(dhDepthTex1, screenPos.xy).r;
			vec3 oScreenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), oDepth);
			vec3 oViewPos = ToNDC(oScreenPos);

			#ifdef OVERWORLD
			vec4 waterFog = getWaterFog(viewPos.xyz - oViewPos, 1.0 + sunVisibility);
			#else
			vec4 waterFog = getWaterFog(viewPos.xyz - oViewPos, 1.5);
			#endif
				 waterFog.a *= max(lightmap.y, 0.2);
				 waterFog.a = min(waterFog.a, 0.75);

			albedo.rgb = mix(sqrt(albedo.rgb), sqrt(waterFog.rgb), waterFog.a);
			albedo.rgb *= albedo.rgb * (1.0 - pow(waterFog.a, 1.5) * 0.5);

			#ifdef OVERWORLD
			albedo.rgb *= 0.5 + timeBrightness * 0.5;
			#endif

			albedo.a = clamp(albedo.a * mix(0.25, 1.5, waterFog.a), 0.1, 0.9);
			#endif
		}

		#ifdef WATER_REFLECTIONS
		if (water > 0.5 || glass > 0.5) {
			float fresnel = clamp(1.0 + dot(normalize(newNormal), nViewPos), 0.0, 1.0 - float(isEyeInWater == 1.0) * 0.5);
			getReflection(albedo, worldPos, viewPos, nViewPos, newNormal, fresnel * (0.5 + water * 0.35), lightmap.y);
			albedo.a = mix(albedo.a, 1.0, fresnel);
		}
		#endif

		#if defined OVERWORLD && !defined DISTANT_HORIZONS
        float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
		float smoothnessF = 0.75 * float(mat == 10000 || water > 0.5);

		vec3 baseReflectance = vec3(0.1);
		vec3 specularHighlight = getSpecularHighlight(newNormal, viewPos, smoothnessF, baseReflectance, lightColSqrt * (2.0 - sunVisibility), shadow * vanillaDiffuse, color.a);
		albedo.rgb += specularHighlight;
		#endif
	}

	//Fog Calculations
	#ifdef END_NEBULA
	vec3 empty = vec3(0.0);
	float nebulaFactor = 0.0;
	float VoU = dot(nViewPos, upVec);
	getEndNebula(skyColor, empty, worldPos, VoU, nebulaFactor, 1.0);
	#endif

	Fog(albedo.rgb, viewPos, worldPos, skyColor);
	albedo.a *= cloudBlendOpacity;

	/* DRAWBUFFERS:03 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(refraction, emission * 0.1 + 0.00135 * float(albedo.a < 0.95), 1.0);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec4 color;
out vec3 eastVec, sunVec, upVec;
out vec3 normal, binormal, tangent;
#if WATER_NORMALS > 0
out vec3 viewVector;
out float viewDistance;
#endif
out vec2 texCoord, lmCoord;
flat out int mat;

//Uniforms//
#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

uniform mat4 gbufferModelView, gbufferModelViewInverse;

//Attributes//
attribute vec4 at_tangent;
attribute vec4 at_midBlock;
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Lightmap Coord
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

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

	//Sun & Other vectors
	#if defined OVERWORLD || defined END
	sunVec = getSunVector(gbufferModelView, timeAngle);
	#endif

	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

	//Materials
	mat = 0;
	if (dhMaterialId == DH_BLOCK_WATER) {
		mat = 10001;
	}

	//Color & Position
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	color = gl_Color;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

	#ifndef DRM_S0L4S
	texCoord.x = texCoord.y;
	#endif
}

#endif