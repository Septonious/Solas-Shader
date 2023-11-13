//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef INTEGRATED_SPECULAR
uniform int isEyeInWater;

#ifdef TAA
uniform int frameCounter;
#endif

uniform float viewHeight, viewWidth;
#endif

uniform sampler2D colortex0;

#ifdef INTEGRATED_SPECULAR
uniform sampler2D noisetex, colortex3;
uniform sampler2D depthtex0, depthtex1;

#ifdef PBR
uniform sampler2D colortex7;
#endif

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
#endif

//Common Variables//
#ifdef INTEGRATED_SPECULAR
const bool colortex0MipmapEnabled = true;
const bool colortex3MipmapEnabled = true;

vec2 viewResolution = vec2(viewWidth, viewHeight);
#endif

//Includes//
#ifdef INTEGRATED_SPECULAR
#include "/lib/util/ToScreen.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/encode.glsl"
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/raytracer.glsl"
#include "/lib/ipbr/simpleReflection.glsl"
#endif

void main() {
	vec4 color = texture2D(colortex0, texCoord);

	#ifdef INTEGRATED_SPECULAR
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	vec3 terrainData = texture2D(colortex3, texCoord).rgb;
	vec3 normal = DecodeNormal(terrainData.rg);
	vec3 viewPos = ToView(vec3(texCoord, z0));

	#ifdef INTEGRATED_SPECULAR
	if (terrainData.b > 0.01 && z0 > 0.56 && z0 >= z1) {
		#ifndef PBR
		float smoothness = terrainData.b;
		#else
		float smoothness = terrainData.b;
			  smoothness *= smoothness;
			  smoothness /= 2.0 - smoothness;
		#endif

		float fresnel = clamp(1.0 + dot(normal, normalize(viewPos)), 0.0, 1.0);
			  fresnel = pow4(fresnel) * smoothness;

		getReflection(color, viewPos, normal, fresnel, smoothness);
	}
	#endif
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;
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