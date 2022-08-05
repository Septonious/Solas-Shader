//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef INTEGRATED_SPECULAR
#if REFLECTION_TYPE == 1
uniform float viewHeight, viewWidth;
#endif

#ifdef TAA
uniform float frameTimeCounter;
#endif

uniform sampler2D colortex2, colortex6;
#endif

uniform sampler2D colortex0;

#ifdef INTEGRATED_SPECULAR
uniform sampler2D depthtex0, depthtex1;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
#endif

//Common Variables//
#if REFLECTION_TYPE == 1 && defined INTEGRATED_SPECULAR
vec2 viewResolution = vec2(viewWidth, viewHeight);
#endif

//Optifine Constants//
#ifdef INTEGRATED_SPECULAR
const bool colortex6MipmapEnabled = true;
#endif

//Includes//
#ifdef INTEGRATED_SPECULAR
#include "/lib/util/ToScreen.glsl"
#include "/lib/util/encode.glsl"

#if REFLECTION_TYPE == 1
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/raytracer.glsl"
#endif

#include "/lib/ipbr/simpleReflection.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef INTEGRATED_SPECULAR
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;
	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec4 terrainData = texture2D(colortex2, texCoord);
	vec3 normal = DecodeNormal(terrainData.rg);
	float roughness = min(mix(texture2D(colortex6, texCoord).a * 100.0, 0.1, float(z0 < z1)), 10.0);
	float specular = terrainData.a;

	if (terrainData.a > 0.05 && roughness >= 0.1 && roughness < 10.0 && z0 > 0.56) {
		float fresnel = clamp(pow4(1.0 + dot(normal, normalize(viewPos.xyz))), 0.0, 1.0);

		vec3 reflection = getReflection(viewPos.xyz, normal, color, roughness);
		color = mix(color, reflection, fresnel * terrainData.a);
	}
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;
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