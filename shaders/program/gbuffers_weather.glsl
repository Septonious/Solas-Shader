#define GBUFFERS_WEATHER

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord, lmCoord;

//Uniforms//
uniform float rainStrength;

uniform sampler2D texture;

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * rainStrength;
	if (albedo.a < 0.01) discard;

	vec2 lightmap = clamp(lmCoord, 0.0, 1.0);

	albedo.a *= 0.25 * length(albedo.rgb * 0.25);
	albedo.rgb = sqrt(albedo.rgb);
	albedo.rgb *= vec3(1.0) + lmCoord.x * lmCoord.x * blockLightCol;

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord, lmCoord;

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Lightmap Coord
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Position
	gl_Position = ftransform();
}

#endif