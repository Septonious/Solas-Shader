#define GBUFFERS_WEATHER

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
uniform float rainStrength;

uniform sampler2D texture;

//Program//
void main() {
    vec4 albedo = texture2D(texture, texCoord) * rainStrength;

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(albedo.rgb, albedo.a * 0.1);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

//Program//
void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    
	//Position
	gl_Position = ftransform();
}

#endif