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

    vec4 vl1 = texture2D(colortex3, newTexCoord + vec2( 0.0,  1.5 / viewHeight));
    vec4 vl2 = texture2D(colortex3, newTexCoord + vec2( 0.0, -1.5 / viewHeight));
    vec4 vl3 = texture2D(colortex3, newTexCoord + vec2( 1.5 / viewWidth,   0.0));
    vec4 vl4 = texture2D(colortex3, newTexCoord + vec2(-1.5 / viewWidth,   0.0));
    vec4 vl = (vl1 + vl2 + vl3 + vl4) * 0.25;
		 vl *= vl;

    vec4 vc1 = texture2D(colortex4, newTexCoord + vec2( 0.0,  1.5 / viewHeight));
    vec4 vc2 = texture2D(colortex4, newTexCoord + vec2( 0.0, -1.5 / viewHeight));
    vec4 vc3 = texture2D(colortex4, newTexCoord + vec2( 1.5 / viewWidth,   0.0));
    vec4 vc4 = texture2D(colortex4, newTexCoord + vec2(-1.5 / viewWidth,   0.0));
    vec4 vc = (vc1 + vc2 + vc3 + vc4) * 0.25;
		 vc *= vc;

	color = mix(color, vc.rgb, pow4(vc.a) * VC_OPACITY);
	color = mix(color, vl.rgb, pow4(vl.a) * VL_OPACITY);
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