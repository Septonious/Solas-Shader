//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef AO
uniform float far, near;
uniform float frameTimeCounter;
uniform float viewWidth, viewHeight, aspectRatio;

#ifdef DISTANT_HORIZONS
uniform float dhFarPlane, dhNearPlane;
uniform sampler2D dhDepthTex0;
#endif

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

    #ifdef DISTANT_HORIZONS
    float z0 = texture2D(depthtex0, texCoord.xy).r;
    if (z0 == 1.0 && z0 > 0.56) {
        ao = computeAmbientOcclusionDH(dither);
    }
    #endif
    #else
    float ao = 1.0;
    #endif

    /* DRAWBUFFERS:1 */
    gl_FragData[0].b = ao;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Position
	gl_Position = ftransform();
}

#endif