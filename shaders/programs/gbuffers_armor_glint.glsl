#define GBUFFERS_ARMOR_GLINT

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec4 color;
in vec2 texCoord;

// Uniforms //
uniform sampler2D texture;

// Main //
void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;
	
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = albedo * 0.5;
}

#endif

//**//**//**//**//**//**//**//**//**//**//**//**//**//**//

#ifdef VSH

// VSH Data //
out vec4 color;
out vec2 texCoord;

// Main //
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	color = gl_Color;

	gl_Position = ftransform();
}

#endif