#define GBUFFERS_BEACONBEAM

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec4 color;
in vec2 texCoord;

// Uniforms //
uniform sampler2D tex;

// Main //
void main() {
	vec4 albedo = texture2D(tex, texCoord) * color;

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(albedo.rgb * 1.5, albedo.a);
}

#endif

//**//**//**//**//**//**//**//**//**//**//**//**//**//**//

#ifdef VSH

// VSH Data //
out vec4 color;
out vec2 texCoord;

// Uniforms //
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

// Main //
void main() {
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    color = gl_Color;

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
}

#endif