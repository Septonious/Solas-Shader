//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_6

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef SSPT
uniform float far, near;
uniform float viewWidth, viewHeight, aspectRatio;

uniform sampler2D colortex6, colortex7;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjection;
#endif

uniform sampler2D colortex0;

//Includes//
#ifdef SSPT
#include "/lib/util/encode.glsl"
#include "/lib/filters/normalAwareBlur.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;
	vec3 sspt = vec3(0.0);

	#ifdef SSPT
	sspt = NormalAwareBlur(48);
	color *= vec3(1.0) + sspt * 16.0;
	#endif

	/* DRAWBUFFERS:0 */
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