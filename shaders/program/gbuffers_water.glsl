//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_WATER

#ifdef FSH

//Varyings//
in float mat;
in vec2 texCoord, lmCoord;

#ifdef WATER_NORMALS
in float viewDistance;
in vec3 viewVector, binormal, tangent;
#endif

in vec3 sunVec, upVec, eastVec, normal;
in vec4 color;

//Uniforms//
uniform int isEyeInWater;

uniform float blindFactor, far;
uniform float nightVision;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight, aspectRatio;
uniform float frameTimeCounter;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform sampler2D texture, noisetex;
uniform sampler2D depthtex1;

#ifdef WATER_REFLECTION
uniform sampler2D colortex5;

uniform mat4 gbufferProjection;
#endif

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility  = clamp((dot( sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);

vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

//Includes//
#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/lighting/forwardLighting.glsl"

#ifdef WATER_FOG
#include "/lib/water/waterFog.glsl"
#endif

#ifdef OVERWORLD
#include "/lib/atmosphere/sky.glsl"
#endif

#include "/lib/atmosphere/fog.glsl"

#ifdef WATER_REFLECTION
#include "/lib/pbr/reflection.glsl"
#endif

#ifdef WATER_NORMALS
#include "/lib/water/waterNormals.glsl"
#endif

#ifdef SSPT
#include "/lib/util/encode.glsl"
#endif

//Program//
void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;
	vec3 newNormal = normal;
	vec3 skyColor = vec3(0.0);
	vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));

	float water = float(mat > 0.9 && mat < 1.1);
	float portal = float(mat > 1.9 && mat < 2.1);

	if (portal > 0.9) {
		vec2 portalCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
		portalCoord = (portalCoord - 0.5) * vec2(aspectRatio, 1.0);

		vec2 wind = vec2(0.0, frameTimeCounter);

		float noise = texture2D(noisetex, portalCoord * 0.20 + wind * 0.009).r * 0.01;
			  noise+= texture2D(noisetex, portalCoord * 0.15 - wind * 0.008).r * 0.02;
			  noise+= texture2D(noisetex, portalCoord * 0.10 + wind * 0.007).r * 0.04;
			  noise+= texture2D(noisetex, portalCoord * 0.05 - wind * 0.006).r * 0.08;
			  noise = clamp(noise, 0.0, 1.0);

		albedo.rgb = mix(vec3(0.5, 0.1, 0.6) * noise, vec3(1.1, 0.2, 1.0) * noise, noise);
		albedo.rgb *= albedo.rgb * 256.0;
		albedo.a = 0.75;
	}

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	vec3 viewPos = ToNDC(screenPos);
	vec3 worldPos = ToWorld(viewPos);

	#ifdef WATER_NORMALS
	if (water > 0.5) {
		albedo.rgb = waterColor.rgb;
		albedo.a = WATER_A;

		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							tangent.y, binormal.y, normal.y,
							tangent.z, binormal.z, normal.z);

		newNormal = clamp(normalize(GetWaterNormal(worldPos, viewPos, viewVector, lightmap) * tbnMatrix), vec3(-1.0), vec3(1.0));
	}
	#endif

	#ifdef OVERWORLD
	skyColor = getAtmosphere(viewPos);

	#if MC_VERSION >= 11900
	skyColor *= 1.0 - darknessFactor;
	#endif
	#endif

	if (albedo.a > 0.001) {
		GetLighting(albedo.rgb, viewPos, worldPos, lightmap, 0.0, 0.0);

		#ifdef WATER_FOG
		if (isEyeInWater == 0 && lightmap.y > 0.0 && water > 0.9) {
			float oDepth = texture2D(depthtex1, screenPos.xy).r;
			vec3 oScreenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), oDepth);
			vec3 oViewPos = ToNDC(oScreenPos);

			vec4 waterFog = getWaterFog(viewPos.xyz - oViewPos);
			albedo = mix(waterFog, vec4(albedo.rgb, 0.75), albedo.a);
		}
		#endif

		if  (water > 0.9) {
			#ifdef WATER_REFLECTION
			float fresnel = clamp(pow4(1.0 + dot(newNormal, normalize(viewPos))) + 0.1 - float(isEyeInWater == 1), 0.0, 1.0);

			vec3 reflection = getReflection(viewPos, newNormal, skyColor * lightmap.y);
			albedo.rgb = mix(albedo.rgb, reflection.rgb, fresnel);
			#endif
		}
	}

	Fog(albedo.rgb, viewPos, skyColor);

    /* DRAWBUFFERS:012 */
    gl_FragData[0] = albedo;
	gl_FragData[1] = texture2D(texture, texCoord) * color;
	gl_FragData[2].a = water;

	#ifdef SSPT
	/* DRAWBUFFERS:0126 */
	gl_FragData[3] = vec4(EncodeNormal(newNormal), float(gl_FragCoord.z < 1.0), 0.0);
	#endif
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out float mat;
out vec2 texCoord, lmCoord;

#ifdef WATER_NORMALS
out float viewDistance;
out vec3 viewVector, binormal, tangent;
#endif

out vec3 sunVec, upVec, eastVec, normal;
out vec4 color;

//Uniforms
#ifdef TAA
uniform int frameCounter;

uniform float viewWidth, viewHeight;
#endif

#if defined OVERWORLD || defined END
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Attributes//
attribute vec4 mc_Entity;

#ifdef WATER_NORMALS
attribute vec4 at_tangent;
#endif

//Includes//
#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Normal
	normal = normalize(gl_NormalMatrix * gl_Normal);

	#ifdef WATER_NORMALS
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
						  tangent.y, binormal.y, normal.y,
						  tangent.z, binormal.z, normal.z);
								  
	viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;
	viewDistance = length(gl_ModelViewMatrix * gl_Vertex);
	#endif

	//Sun & Other vectors
	#if defined OVERWORLD || defined END
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	
	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);
	#endif

	//Materials
	mat = 0.0;

	if (mc_Entity.x == 1) mat = 1.0;
	if (mc_Entity.x == 2) mat = 2.0;

	//Color & Position
	color = gl_Color;

	gl_Position = ftransform();
	
	#ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif