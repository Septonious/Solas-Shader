#define GBUFFERS_WATER

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
flat in int mat;
in float viewDistance;
in vec2 texCoord;
in vec2 lmCoord;
in vec3 normal, binormal, tangent, viewVector;
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

uniform float frameTimeCounter;
uniform float far, near;
uniform float viewWidth, viewHeight;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform float blindFactor;
uniform float nightVision;

#ifdef OVERWORLD
uniform float timeBrightness, timeAngle;
uniform float shadowFade;
uniform float wetness;
#endif

#ifdef AURORA
uniform float isSnowy;
uniform int moonPhase;
#endif

uniform ivec2 eyeBrightnessSmooth;

#ifdef OVERWORLD
uniform vec3 skyColor;
#endif

uniform vec3 fogColor;
uniform vec3 cameraPosition;

uniform sampler2D texture;
uniform sampler2D noisetex;
uniform sampler2D depthtex1;
uniform sampler2D gaux1;

#ifdef SKYBOX
uniform sampler2D gaux4;
#endif

#ifdef WATER_REFLECTIONS
uniform sampler2D gaux3;

uniform mat4 gbufferProjection;
#endif

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
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/transformMacros.glsl"
#include "/lib/util/encode.glsl"
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/color/netherColor.glsl"
#include "/lib/vx/blocklightColor.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/gbuffersLighting.glsl"

#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

#ifdef OVERWORLD
#include "/lib/atmosphere/sky.glsl"
#endif

#ifdef END_NEBULA
#include "/lib/atmosphere/skyEffects.glsl"
#endif

#include "/lib/atmosphere/fog.glsl"

#ifdef WATER_REFLECTIONS
#include "/lib/pbr/raytracer.glsl"
#include "/lib/pbr/waterReflection.glsl"
#endif

#ifdef OVERWORLD
#include "/lib/pbr/ggx.glsl"
#endif

#include "/lib/water/waterFog.glsl"

#if WATER_NORMALS > 0
#include "/lib/water/waterNormals.glsl"
#endif

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;

	if (mat == 10001) {
		albedo.rgb = mix(color.rgb, waterColor.rgb, 0.5);
		albedo.a = WATER_A;
	}

	vec3 newNormal = normal;
	vec2 refraction = vec2(0.0);
	float emission = pow8(lmCoord.x) + int(mat == 10031) * pow4(length(albedo.rgb)) * 2.0;
	float cloudBlendOpacity = 1.0;

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	#ifdef TAA
	vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
	#else
	vec3 viewPos = ToNDC(screenPos);
	#endif
	vec3 nViewPos = normalize(viewPos);
	vec3 worldPos = ToWorld(viewPos);
	vec2 lightmap = clamp(lmCoord, 0.0, 1.0);

	#ifdef VC
	float cloudDepth = texture2D(gaux1, screenPos.xy).g * (far * 2.0);

	float viewLength = length(viewPos);
	cloudBlendOpacity = step(viewLength, cloudDepth);

	if (cloudBlendOpacity == 0) {
		discard;
	}
	#endif

	#if WATER_NORMALS > 0
	if (mat == 10001) {
		float fresnel = clamp(1.0 + dot(normalize(normal), nViewPos), 0.0, 1.0);
		getWaterNormal(newNormal, worldPos, fresnel);
	}
	#endif

	refraction = (newNormal.xy - normal.xy) * 0.5 + 0.5;

	float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
	float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
	float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

    //Atmosphere
	#if defined OVERWORLD
	vec3 sunPos = vec3(gbufferModelViewInverse * vec4(sunVec * 128.0, 1.0));
	vec3 sunCoord = sunPos / (sunPos.y + length(sunPos.xz));
    vec3 atmosphereColor = getAtmosphericScattering(viewPos, normalize(sunCoord));

	#ifdef SKYBOX
	vec3 skybox = texture2D(gaux4, texCoord.xy).rgb;
	if (length(pow(skybox, vec3(0.1))) > 0.0) atmosphereColor = mix(atmosphereColor, skybox, SKYBOX_MIX_FACTOR);
	#endif
	#elif defined NETHER
	vec3 atmosphereColor = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 atmosphereColor = endLightCol * 0.1;
	#endif

    vec3 skyColor = atmosphereColor;

	vec3 shadow = vec3(0.0);
	gbuffersLighting(albedo, screenPos, viewPos, worldPos, shadow, lightmap, NoU, NoL, NoE, 0.0, 0.0, emission, 0.0);

	if (mat != 10031) {
		if (mat == 10001 && isEyeInWater == 0) {
			#ifdef WATER_FOG
			float oDepth = texture2D(depthtex1, screenPos.xy).r;
			vec3 oScreenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), oDepth);
			vec3 oViewPos = ToNDC(oScreenPos);

			#ifdef OVERWORLD
			vec4 waterFog = getWaterFog(viewPos.xyz - oViewPos, 1.0 + sunVisibility);
			#else
			vec4 waterFog = getWaterFog(viewPos.xyz - oViewPos, 1.5);
			#endif
				 waterFog.a *= max(lightmap.y, 0.2);

			albedo.rgb = mix(sqrt(albedo.rgb), sqrt(waterFog.rgb), waterFog.a);
			albedo.rgb *= albedo.rgb * (1.0 - pow(waterFog.a, 1.5) * 0.65);

			#ifdef OVERWORLD
			albedo.rgb *= (0.5 + timeBrightness * 0.5);
			#endif

			albedo.a = clamp(albedo.a * mix(0.25, 1.5, waterFog.a), 0.05, 0.95);
			#endif
		}

		#ifdef WATER_REFLECTIONS
		float fresnel = clamp(1.0 + dot(normalize(newNormal), nViewPos), 0.0, 1.0 - float(isEyeInWater == 1.0) * 0.5);
		getReflection(albedo, viewPos, nViewPos, newNormal, fresnel, lightmap.y);
		albedo.a = mix(albedo.a, 1.0, fresnel);
		#endif

		#ifdef OVERWORLD
        float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
		float smoothnessF = 0.6 + length(albedo.rgb) * 0.2 * float(mat == 10000 || mat == 10001);

		vec3 baseReflectance = vec3(0.1);
		vec3 specularHighlight = getSpecularHighlight(newNormal, viewPos, smoothnessF, baseReflectance, lightColSqrt, shadow * vanillaDiffuse, color.a);
		albedo.rgb += specularHighlight;
		#endif
	}

	//Atmosphere & Fog
	#ifdef END_NEBULA
	float nebulaFactor = 0.0;
	float VoU = dot(nViewPos, upVec);
	getEndNebula(skyColor, worldPos, VoU, nebulaFactor, 1.0);
	#endif

	Fog(albedo.rgb, viewPos, worldPos, skyColor);

	albedo.a *= cloudBlendOpacity;

	/* DRAWBUFFERS:03 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(refraction, emission * 0.1 + 0.00135, 1.0);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
flat out int mat;
out float viewDistance;
out vec2 texCoord;
out vec2 lmCoord;
out vec3 normal, binormal, tangent, viewVector;
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

//Attributes//
attribute vec4 at_tangent;
attribute vec4 mc_Entity;

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

	//Normal, Binormal and Tangent
	normal = normalize(gl_NormalMatrix * gl_Normal);
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent = normalize(gl_NormalMatrix * at_tangent.xyz);

	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
						  tangent.y, binormal.y, normal.y,
						  tangent.z, binormal.z, normal.z);

	viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;
	viewDistance = length(gl_ModelViewMatrix * gl_Vertex);

	//Sun & Other vectors
	#if defined OVERWORLD || defined END
	sunVec = getSunVector(gbufferModelView, timeAngle);
	#endif
	
	upVec = normalize(gbufferModelView[1].xyz);
	northVec = normalize(gbufferModelView[2].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

	//Materials
	mat = int(mc_Entity.x + 0.5);

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