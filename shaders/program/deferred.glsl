//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
varying vec2 texCoord;

//Uniforms//
#ifdef AO
uniform int frameCounter;

uniform float far, near;
uniform float viewWidth, viewHeight, aspectRatio;

uniform sampler2D depthtex0;
uniform sampler2D noisetex;

uniform mat4 gbufferProjection;
#endif

uniform sampler2D colortex0;

//Includes//
#ifdef AO
#include "/lib/util/bayerDithering.glsl"
#include "/lib/lighting/computeAmbientOcclusion.glsl"
#endif

//Program//
void main() {
    vec3 color = texture2D(colortex0, texCoord).rgb;

    #ifdef AO
	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif

    float ao = computeAmbientOcclusion(blueNoiseDither);

    color.rgb *= ao;
    #endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
varying vec2 texCoord;

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();
}

#endif