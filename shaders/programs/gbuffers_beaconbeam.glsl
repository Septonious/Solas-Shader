#define GBUFFERS_BEACONBEAM

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec4 color;
//in vec3 worldPos;
in vec2 texCoord;

// Uniforms //
uniform sampler2D texture;

//uniform vec3 cameraPosition;

// Main //
void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;

	//albedo.a *= 1.0 - clamp((worldPos.y + cameraPosition.y) / 100.0, 0.0, 1.0);

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(albedo.rgb * 1.5, albedo.a);
}

#endif

//**//**//**//**//**//**//**//**//**//**//**//**//**//**//

#ifdef VSH

// VSH Data //
out vec4 color;
///out vec3 worldPos;
out vec2 texCoord;

// Uniforms //
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

// Main //
void main() {
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Color & Position
    color = gl_Color;

	//Position
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	//worldPos = position.xyz;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
}

#endif