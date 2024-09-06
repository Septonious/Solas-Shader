//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_1

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef GI
uniform float far, near;
uniform float viewWidth, viewHeight;

uniform sampler2D depthtex0;

uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
#endif

uniform sampler2D colortex0;

//Buffers Config//
const bool colortex4MipmapEnabled = true;
const bool colortex5Clear = false;

//Includes//
#ifdef GI
#include "/lib/util/encode.glsl"
#include "/lib/filters/ssptDenoiser.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef GI
    vec3 gi = denoiseSSPT(colortex4, texCoord);

    vec3 previousColor = texture2D(colortex5, texCoord).gba;
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;

    #ifdef GI
    /* DRAWBUFFERS:045 */
    gl_FragData[1].rgb = gi;
    gl_FragData[2].gba = previousColor;
    #endif
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