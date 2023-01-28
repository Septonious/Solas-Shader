//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef SSGI
uniform int frameCounter;
#endif

#ifdef INTEGRATED_SPECULAR
uniform int isEyeInWater;

uniform float viewHeight, viewWidth;

#ifdef TAA
uniform float frameTimeCounter;
#endif
#endif

#if defined INTEGRATED_SPECULAR || defined SSGI
uniform sampler2D colortex2;

#ifdef SSGI
uniform sampler2D noisetex;
#endif
#endif

uniform sampler2D colortex0;

#if defined INTEGRATED_SPECULAR || defined SSGI
uniform sampler2D depthtex0, depthtex1;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
#endif

//Common Variables//
#ifdef INTEGRATED_SPECULAR
vec2 viewResolution = vec2(viewWidth, viewHeight);
#endif

//Includes//
#if defined INTEGRATED_SPECULAR || defined SSGI
#include "/lib/util/ToScreen.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/encode.glsl"
#endif

#ifdef INTEGRATED_SPECULAR
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/raytracer.glsl"
#include "/lib/ipbr/simpleReflection.glsl"
#endif

#ifdef SSGI
#include "/lib/util/blueNoiseDithering.glsl"
#include "/lib/lighting/ssgi.glsl"
#endif

void main() {
	vec4 color = texture2D(colortex0, texCoord);
	vec3 ssgi = vec3(0.0);

	#if defined INTEGRATED_SPECULAR || defined SSGI
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	vec4 terrainData = texture2D(colortex2, texCoord);
	vec3 normal = DecodeNormal(terrainData.rg);
	vec3 viewPos = ToView(vec3(texCoord, z0));

	#ifdef INTEGRATED_SPECULAR
	if (terrainData.a > 0.05 && terrainData.a < 1.0 && z0 > 0.56 && z0 >= z1) {
		float fresnel = pow4(clamp(1.0 + dot(normal, normalize(viewPos)), 0.0, 1.0));

		getReflection(color, viewPos, normal, fresnel * terrainData.a);
	}
	#endif

	#ifdef SSGI
	float viewDistance = 1.0 - clamp(length(viewPos) * 0.02, 0.0, 1.0);

	if (viewDistance > 0.0 && z0 > 0.56 && terrainData.b == 0.0) {
		ssgi = computeSSGI(vec3(texCoord, z0), normal);
	}
	#endif
	#endif

	/* DRAWBUFFERS:06 */
	gl_FragData[0] = color;
	gl_FragData[1].rgb = ssgi;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}

#endif