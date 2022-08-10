//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#if defined VC || defined VL
uniform float viewWidth, viewHeight;

#ifdef VL
uniform sampler2D colortex3;
#endif

#ifdef VC
uniform sampler2D colortex4;
#endif
#endif

uniform sampler2D colortex0;

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#if defined VC || defined VL
	vec2 newTexCoord = texCoord * VOLUMETRICS_RESOLUTION;
	vec4 vl = vec4(0.0);
	vec4 vc = vec4(0.0);

	#ifdef VL
    vec4 vl1 = texture2D(colortex3, newTexCoord + vec2( 0.0,  1.0 / viewHeight));
    vec4 vl2 = texture2D(colortex3, newTexCoord + vec2( 0.0, -1.0 / viewHeight));
    vec4 vl3 = texture2D(colortex3, newTexCoord + vec2( 1.0 / viewWidth,   0.0));
    vec4 vl4 = texture2D(colortex3, newTexCoord + vec2(-1.0 / viewWidth,   0.0));
    	 vl = (vl1 + vl2 + vl3 + vl4) * 0.25;
		 vl *= vl;
	#endif

	#ifdef VC
    vec4 vc1 = texture2D(colortex4, newTexCoord + vec2( 0.0,  1.0 / viewHeight));
    vec4 vc2 = texture2D(colortex4, newTexCoord + vec2( 0.0, -1.0 / viewHeight));
    vec4 vc3 = texture2D(colortex4, newTexCoord + vec2( 1.0 / viewWidth,   0.0));
    vec4 vc4 = texture2D(colortex4, newTexCoord + vec2(-1.0 / viewWidth,   0.0));
    	 vc = (vc1 + vc2 + vc3 + vc4) * 0.25;
		 vc *= vc;
	#endif

	color = mix(color, vc.rgb, pow4(vc.a) * VC_OPACITY);
	color = mix(color, vl.rgb, pow4(vl.a) * VL_OPACITY * VL_OPACITY);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;

	#if defined VC && defined TAA
	/* DRAWBUFFERS:04 */
	gl_FragData[1].a = pow4(vc.a);
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