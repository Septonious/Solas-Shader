//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_5

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef SSPT
uniform float far, near;
uniform float viewWidth, viewHeight;

uniform sampler2D colortex6, colortex7;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjection;
#endif

//Includes//
#ifdef SSPT
#include "/lib/util/encode.glsl"
#include "/lib/filters/normalAwareBlur.glsl"
#endif

//Program//
void main() {
	#ifndef SSPT
	discard;
	#endif

	vec3 sspt = vec3(0.0);

	#ifdef SSPT
	sspt = NormalAwareBlur(24);
	#endif

	/* DRAWBUFFERS:7 */
	gl_FragData[0].rgb = sspt;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

//Program//
void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Position
	gl_Position = ftransform();
}

#endif
