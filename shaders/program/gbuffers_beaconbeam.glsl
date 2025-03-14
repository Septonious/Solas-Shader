//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_BEACONBEAM

#ifdef FSH

//Varyings//
in vec4 color;
in vec2 texCoord;

//Uniforms//
uniform sampler2D texture;

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(albedo.rgb * 1.5, albedo.a);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec4 color;
out vec2 texCoord;

//Program//
void main() {
	//Coord
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Color & Position
    color = gl_Color;

	gl_Position = ftransform();
}

#endif