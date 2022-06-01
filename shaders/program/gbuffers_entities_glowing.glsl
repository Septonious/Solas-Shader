//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_ENTITIES_GLOWING

#ifdef FSH

//Varyings//
varying vec2 texCoord;
varying vec4 color;

//Uniforms//
uniform sampler2D texture;

//Program//
void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;

    /* DRAWBUFFERS:02 */
    gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(0.0, 0.0, 1.0, 0.0);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
varying vec2 texCoord;
varying vec4 color;

void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Color & Position
	color = gl_Color;

	gl_Position = ftransform();
}

#endif