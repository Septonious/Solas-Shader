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
#include "/lib/lighting/computeAmbientOcclusion.glsl"
#endif

//Program//
void main() {
    float ao = 0.0;

    #ifdef AO
    float z0 = texture2D(depthtex0, texCoord).r;

    if (z0 != 1.0 && z0 > 0.56) ao = computeAmbientOcclusion(getLinearDepth(z0), Bayer64(gl_FragCoord.xy));
    #endif

    /* DRAWBUFFERS:4 */
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