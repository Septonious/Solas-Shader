//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#if defined VL || defined VF_NETHER_END
uniform float viewHeight, viewWidth;

uniform sampler2D colortex1;
#endif

uniform sampler2D colortex0;

#if defined VF_NETHER_END && defined END
#include "/lib/filters/blur.glsl"
#endif

const bool colortex1MipmapEnabled = true;

void main() {
	vec4 color = texture2D(colortex0, texCoord);

	#if defined VL || defined VF_NETHER_END
	#if defined OVERWORLD || defined NETHER
    vec3 vl1 = texture2DLod(colortex1, texCoord + vec2( 0.0,  2.0 / viewHeight), 1.0).rgb;
    vec3 vl2 = texture2DLod(colortex1, texCoord + vec2( 0.0, -2.0 / viewHeight), 1.0).rgb;
    vec3 vl3 = texture2DLod(colortex1, texCoord + vec2( 2.0 / viewWidth,   0.0), 1.0).rgb;
    vec3 vl4 = texture2DLod(colortex1, texCoord + vec2(-2.0 / viewWidth,   0.0), 1.0).rgb;
	vec3 vl = (vl1 + vl2 + vl3 + vl4) * 0.25;
	#else
	vec4 vl = getDiskBlur16(colortex1, texCoord, 6.0);
	#endif

	#ifdef OVERWORLD
	vl *= vl * VL_STRENGTH * 0.25;
	color.rgb += vl;
	#else
	vl.rgb *= vl.rgb;

	#ifdef END
	color.rgb = mix(color.rgb, vl.rgb, vl.a);
	#else
	color.rgb += vl;
	#endif
	#endif
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}

#endif