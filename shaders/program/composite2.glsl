//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef VC
uniform float viewWidth, viewHeight;

uniform sampler2D colortex3, colortex4;
#endif

uniform sampler2D colortex0;

//Includes//
#ifdef VC
#include "/lib/filters/blur.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef VC
	vec2 newTexCoord = texCoord * VOLUMETRICS_RESOLUTION;
    vec4 clouds0 = getDiskBlur4(colortex3, newTexCoord, 1.0 / VOLUMETRICS_RESOLUTION);
		 clouds0 *= clouds0;

    vec4 clouds1 = getDiskBlur4(colortex4, newTexCoord, 1.0 / VOLUMETRICS_RESOLUTION);
		 clouds1 *= clouds1;

	color = mix(color, clouds1.rgb, pow6(clouds1.a) * VC_OPACITY);
	color = mix(color, clouds0.rgb, pow4(clouds0.a));
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;
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