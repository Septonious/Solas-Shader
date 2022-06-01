//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_2

#ifdef FSH

//Varyings//
varying vec2 texCoord;

//Uniforms//
uniform sampler2D colortex0;

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	/*DRAWBUFFERS:0*/
	gl_FragData[0].rgb = color;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
varying vec2 texCoord;

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();
}

#endif
