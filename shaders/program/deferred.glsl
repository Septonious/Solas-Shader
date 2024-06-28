//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
varying vec2 texCoord;

//Uniforms//
#ifdef AO
uniform float far, near;
uniform float frameTimeCounter;
uniform float viewWidth, viewHeight, aspectRatio;

uniform sampler2D depthtex0;
uniform mat4 gbufferProjection;
#endif

//Includes//
#ifdef AO
#include "/lib/util/bayerDithering.glsl"
#include "/lib/lighting/computeAmbientOcclusion.glsl"
#endif

//Program//
void main() {
    #ifdef AO
    float dither = Bayer8(gl_FragCoord.xy);
    
    #ifdef TAA
	dither = fract(dither + frameTimeCounter * 16.0);
	#endif

    float ao = computeAmbientOcclusion(dither);
    #else
    float ao = 1.0;
    #endif

    /* DRAWBUFFERS:1 */
    gl_FragData[0].a = ao;
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