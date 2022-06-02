//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_WEATHER

#ifdef FSH

//Varyings//
in vec2 texCoord, lmCoord;
in vec4 color;

//Uniforms//
uniform float rainStrength;

uniform sampler2D texture;

//Includes//
#include "/lib/color/blocklightColor.glsl"

//Program//
void main() {
    vec4 albedo = vec4(0.0);
	albedo.a = texture2D(texture, texCoord).a;

	vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));

	if (albedo.a > 0.001) {
		albedo.rgb = texture2D(texture, texCoord).rgb;

		albedo.a *= 0.2 * rainStrength * length(albedo.rgb / 3.0);
		albedo.rgb = sqrt(albedo.rgb);
		albedo.rgb *= (vec3(1.0) + lmCoord.x * lmCoord.x * blocklightCol) * 0.75;

		#if MC_VERSION < 10800
		albedo.a *= 4.0;
		albedo.rgb *= 0.525;
		#endif
	}

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = albedo;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord, lmCoord;
out vec4 color;

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));
    
	color = gl_Color;

	gl_Position = ftransform();
}

#endif