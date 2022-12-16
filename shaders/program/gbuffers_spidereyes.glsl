#define GBUFFERS_SPIDEREYES

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;
in vec4 color;

//Uniforms//
uniform sampler2D texture;

//Program//
void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = albedo;

	#ifdef BLOOM
	/* DRAWBUFFERS:02 */
	gl_FragData[1].ba = vec2(0.5, 1.0);
	#endif
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;
out vec4 color;

//Program//
void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    
	//Color & Position
	color = gl_Color;

	gl_Position = ftransform();
}

#endif