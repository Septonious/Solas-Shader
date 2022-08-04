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
    vec4 vl = getDiskBlur4(colortex3, newTexCoord, 0.75 / VOLUMETRICS_RESOLUTION);
		 vl *= vl;

    vec4 vc = getDiskBlur8(colortex4, newTexCoord, 1.5 / VOLUMETRICS_RESOLUTION);
		 vc *= vc;

	color = mix(color, vc.rgb, pow2(vc.a) * VC_OPACITY);
	color = mix(color, vl.rgb, vl.a);
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