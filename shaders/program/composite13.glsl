//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_13

#ifdef FSH

//Varyings//
varying vec2 texCoord;

//Uniforms//
#ifdef BLOOM
uniform float viewWidth, viewHeight, aspectRatio;
#endif

uniform sampler2D colortex0;

//Includes//
#ifdef BLOOM
#include "/lib/post/bloom.glsl"
#endif

void main() {
	vec3 blur = vec3(1.0);

	#ifdef BLOOM
	blur = getBlur(texCoord);
	#endif

	/* DRAWBUFFERS:1 */
	gl_FragData[0] = vec4(blur, 1.0);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
varying vec2 texCoord;

void main() {
	texCoord = gl_MultiTexCoord0.xy;

	gl_Position = ftransform();
}

#endif