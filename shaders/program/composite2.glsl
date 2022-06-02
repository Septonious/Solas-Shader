//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_2

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef DOF
uniform float centerDepthSmooth;
#endif

#if defined DOF || defined DISTANT_BLUR
uniform float viewHeight, aspectRatio;

uniform mat4 gbufferProjection;

uniform sampler2D depthtex1;
#endif

#ifdef DISTANT_BLUR
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
#endif

uniform sampler2D colortex0;

//Optifine Constants//
#if defined DOF || defined DISTANT_BLUR
const bool colortex0MipmapEnabled = true;
#endif

//Includes//
#if defined DOF || defined DISTANT_BLUR
#include "/lib/post/dofBlur.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;
	vec4 viewPos = vec4(0.0);

	#ifdef DISTANT_BLUR
	float z0 = texture2D(depthtex0, texCoord).x;
	vec4 screenPos = vec4(texCoord, z0, 1.0);
	viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;
	#endif

	#if defined DOF || defined DISTANT_BLUR
	color = getBlur(color, viewPos.xyz);
	#endif

	/*DRAWBUFFERS:0*/
	gl_FragData[0].rgb = color;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	gl_Position = ftransform();
}

#endif
