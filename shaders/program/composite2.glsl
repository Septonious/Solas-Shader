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

vec2 vlOffsets[4] = vec2[4](
	vec2( 1.5,  0.5),
	vec2(-0.5,  1.5),
	vec2(-1.5, -0.5),
	vec2( 0.5, -1.5)
);

void main() {
	vec4 color = texture2D(colortex0, texCoord);

	#if defined VL || defined VF_NETHER_END
	#if defined OVERWORLD || defined NETHER
	vec3 vl = texture2D(colortex1, texCoord + vlOffsets[0] / vec2(viewWidth, viewHeight)).rgb;
		 vl+= texture2D(colortex1, texCoord + vlOffsets[1] / vec2(viewWidth, viewHeight)).rgb;
		 vl+= texture2D(colortex1, texCoord + vlOffsets[2] / vec2(viewWidth, viewHeight)).rgb;
		 vl+= texture2D(colortex1, texCoord + vlOffsets[3] / vec2(viewWidth, viewHeight)).rgb;
	vl *= 0.25;
	#else
	vec4 vl = getDiskBlur16(colortex1, texCoord, 6.0);
	#endif

	#ifdef OVERWORLD
	vl = pow4(vl) * 128.0 * VL_STRENGTH * 0.25;
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