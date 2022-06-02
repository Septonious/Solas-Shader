//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_4

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef SSPT
uniform float far, near;
uniform float viewWidth, viewHeight;

uniform sampler2D colortex5, colortex6;
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
	vec3 sspt = vec3(0.0);

	#ifdef SSPT
	sspt = NormalAwareBlur();
	#endif

	/* DRAWBUFFERS:6 */
	gl_FragData[0].rgb = sspt;
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
