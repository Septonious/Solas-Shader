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

uniform sampler2D depthtex0, noisetex;

uniform mat4 gbufferProjection;
#endif

//Includes//
#ifdef AO
#include "/lib/util/bayerDithering.glsl"
#include "/lib/lighting/calculateAmbientOcclusion.glsl"
#endif

//Program//
void main() {
    #ifdef AO
    float ao = calculateAmbientOcclusion(Bayer64(gl_FragCoord.xy));
    #else
    float ao = 1.0;
    #endif

    /* DRAWBUFFERS:4 */
    gl_FragData[0].r = ao;
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