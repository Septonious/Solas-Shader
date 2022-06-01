//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
varying vec4 color;
varying vec2 texCoord;

//Uniforms//
uniform sampler2D texture;

void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
varying vec4 color;
varying vec2 texCoord;

void main() {
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    color = gl_Color;

	gl_Position = ftransform();
}

#endif