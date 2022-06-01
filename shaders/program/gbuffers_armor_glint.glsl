//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_ARMOR_GLINT

#ifdef FSH

//Varyings//
varying vec2 texCoord;
varying vec4 color;

//Uniforms//
uniform sampler2D texture;

//Program//
void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;
	albedo *= 0.35;

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = albedo;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
varying vec2 texCoord;
varying vec4 color;

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    
	color = gl_Color;

	gl_Position = ftransform();
}

#endif