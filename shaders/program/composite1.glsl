//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef INTEGRATED_SPECULAR
uniform int isEyeInWater;

#ifdef TAA
uniform float frameTimeCounter;
#endif

uniform sampler2D colortex2;
#endif

#if defined INTEGRATED_SPECULAR || defined VL
uniform float viewHeight, viewWidth;
#endif

#ifdef VL
uniform sampler2D colortex1;
#endif

uniform sampler2D colortex0;

#ifdef INTEGRATED_SPECULAR
uniform sampler2D depthtex0, depthtex1;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
#endif

//Common Variables//
#ifdef INTEGRATED_SPECULAR
vec2 viewResolution = vec2(viewWidth, viewHeight);
#endif

//Optifine Constants//
#ifdef VL
const bool colortex1MipmapEnabled = true;
#endif

//Includes//
#ifdef VL
#include "/lib/filters/blur.glsl"
#endif

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

	#ifdef VL
	vec3 vl = getDiskBlur8(colortex1, texCoord, 1.5).rgb;
	color.rgb += vl * vl;
	#endif

	#ifdef INTEGRATED_SPECULAR
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;
	vec3 viewPos = ToView(vec3(texCoord, z0));

	vec4 terrainData = texture2D(colortex2, texCoord);
	vec3 normal = DecodeNormal(terrainData.rg);

	if (terrainData.a > 0.05 && terrainData.a < 1.0 && z0 > 0.56 && z0 >= z1) {
		float fresnel = pow2(clamp(1.0 + dot(normal, normalize(viewPos)), 0.0, 1.0));

		getReflection(color, viewPos, normal, fresnel * terrainData.a);
	}
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