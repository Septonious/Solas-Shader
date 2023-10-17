//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_BEACONBEAM

#ifdef FSH

//Varyings//
in vec2 texCoord;
in vec4 color;

//Uniforms//
uniform sampler2D texture;

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;
	float lAlbedo = length(albedo.rgb);
		 albedo.rgb *= 1.0 + clamp(pow12(lAlbedo), 0.0, 1.0);

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;
out vec4 color;

//Program//
void main() {
	//Coord
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Color & Position
    color = gl_Color;

	gl_Position = ftransform();
}

#endif