//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
uniform int renderStage;

in vec2 texCoord;
in vec4 color;

uniform sampler2D texture;

//Pipeline Constans//
const bool colortex7Clear = false;
const bool gaux4Clear = false;

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord) * color;
		 albedo.rgb = pow(albedo.rgb, vec3(2.2)) * albedo.a;
		 albedo.rgb = sqrt(max(albedo.rgb, vec3(0.0)));
	
	if (renderStage == MC_RENDER_STAGE_SUN || renderStage == MC_RENDER_STAGE_MOON) {
		albedo *= 0.0;
	}

    /* DRAWBUFFERS:7 */
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