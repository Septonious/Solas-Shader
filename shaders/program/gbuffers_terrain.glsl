//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_TERRAIN

#ifdef FSH

//Varyings//
in float mat;

#ifdef INTEGRATED_EMISSION
in float isPlant;
#endif

in vec2 texCoord, lmCoord;
in vec3 sunVec, upVec, eastVec, normal;
in vec4 color;

//Uniforms//
uniform float nightVision;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;

uniform vec3 cameraPosition;

uniform sampler2D texture;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

//Common Variables//
float sunVisibility  = clamp((dot( sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);

vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

//Includes//
#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/dimensionColor.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/lighting/forwardLighting.glsl"

#ifdef INTEGRATED_EMISSION
#include "/lib/lighting/integratedEmissionTerrain.glsl"
#endif

#ifdef SSPT
#include "/lib/util/encode.glsl"
#endif

//Program//
void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;
	vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	vec3 viewPos = ToNDC(screenPos);
	vec3 worldPos = ToWorld(viewPos);

	float emissive = 0.0;

	#if defined SSPT && defined EMISSIVE_CONCRETE
	emissive += float(mat > 198.9 && mat < 199.9) * 1.5;
	#endif

	if (albedo.a > 0.001){
		float subsurface = float(mat > 0.99 && mat < 1.01);
		
		#ifdef INTEGRATED_EMISSION
		getIntegratedEmission(emissive, lightmap, albedo, worldPos);
		#endif

		GetLighting(albedo.rgb, viewPos, worldPos, lightmap, emissive, subsurface);
	}

    /* DRAWBUFFERS:05 */
    gl_FragData[0] = albedo;
	gl_FragData[1] = albedo;

	#ifdef SSPT
	/* DRAWBUFFERS:056 */
	gl_FragData[2] = vec4(EncodeNormal(normal), float(gl_FragCoord.z < 1.0), emissive);
	#endif
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out float mat;

#ifdef INTEGRATED_EMISSION
out float isPlant;
#endif

out vec2 texCoord, lmCoord;
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

//Includes//
#ifdef INTEGRATED_EMISSION
#include "/lib/lighting/integratedEmissionTerrain.glsl"
#endif

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

	if (mc_Entity.x >= 4 && mc_Entity.x <= 13) mat = 1.0;

	#if defined SSPT && defined EMISSIVE_CONCRETE
	if (mc_Entity.x == 199) mat = 199;
	#endif

	#ifdef INTEGRATED_EMISSION
	isPlant = 0.0;

	getIntegratedEmissionMaterials(mat, isPlant);
	#endif

	//Color & Position
	color = gl_Color;

	gl_Position = ftransform();

	#ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif