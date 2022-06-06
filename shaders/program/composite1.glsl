//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_1

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#if defined VL || defined VCLOUDS
uniform float viewWidth, viewHeight;

#ifdef VCLOUDS
uniform sampler2D colortex4;
#endif

#ifdef VL
uniform sampler2D colortex1;
#endif
#endif

uniform sampler2D colortex0;

//Includes//
#if defined VL || defined VCLOUDS
#include "/lib/filters/blur.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#if defined VL || defined VCLOUDS
	vec2 newTexCoord = texCoord * VOLUMETRICS_RESOLUTION;
	#endif

	#ifdef VL
    vec3 vl = getDiskBlur8(colortex1, newTexCoord, 1.5 / VOLUMETRICS_RESOLUTION).rgb;

	color += vl * VL_STRENGTH * 0.5;
	#endif

	#ifdef VCLOUDS
    vec4 clouds = getDiskBlur8(colortex4, newTexCoord, 1.5 / VOLUMETRICS_RESOLUTION);

	color = mix(color, clouds.rgb, pow4(clouds.a) * 0.75);
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
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
}

#endif