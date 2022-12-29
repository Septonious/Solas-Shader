//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef VL
uniform float viewHeight, viewWidth;

uniform sampler2D colortex6;
#endif

uniform sampler2D colortex0;

//Common Functions//
#if defined VL && defined VL_SCENE_BLURRING
float getLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}
#endif

//Optifine Constants//
#if defined VL && defined VL_SCENE_BLURRING
const bool colortex6MipmapEnabled = true;

//Includes//
#include "/lib/filters/blur.glsl"
#endif

void main() {
	vec4 color = texture2D(colortex0, texCoord);

	#ifdef VL
    vec3 vl1 = texture2DLod(colortex6, texCoord + vec2( 0.0,  1.0 / viewHeight), 1.0).rgb;
    vec3 vl2 = texture2DLod(colortex6, texCoord + vec2( 0.0, -1.0 / viewHeight), 1.0).rgb;
    vec3 vl3 = texture2DLod(colortex6, texCoord + vec2( 1.0 / viewWidth,   0.0), 1.0).rgb;
    vec3 vl4 = texture2DLod(colortex6, texCoord + vec2(-1.0 / viewWidth,   0.0), 1.0).rgb;
    vec3 vl = (vl1 + vl2 + vl3 + vl4) * 0.25;
	vl *= vl * VL_STRENGTH;

	#ifdef VL_SCENE_BLURRING
	if (vl != vec3(0.0)) {
		float blurringFactor = getLuminance(vl) * 16.0;
		vec3 blurredColor = getDiskBlur8RGBLOD(colortex0, texCoord, clamp(blurringFactor * 8.0, 0.0, 4.0), 2.0);
		color.rgb = mix(color.rgb, blurredColor, clamp(blurringFactor, 0.0, 1.0));
	}
	#endif

	color.rgb += vl;
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