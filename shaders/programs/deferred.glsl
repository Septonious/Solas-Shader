#define DEFERRED_0

//Settings//
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
uniform float far, near;
uniform float frameTimeCounter;
uniform float viewWidth, viewHeight, aspectRatio;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform sampler2D depthtex0;

#ifdef VOXY
uniform mat4 vxProjInv;

uniform sampler2D vxDepthTexOpaque;
#endif

#ifdef DISTANT_HORIZONS
uniform float dhFarPlane, dhNearPlane;

uniform mat4 dhProjectionInverse;
uniform sampler2D dhDepthTex0;
#endif

// Includes //
#include "/lib/util/bayerDithering.glsl"
#include "/lib/lighting/ambientOcclusion.glsl"

// Main //
void main() {
    float ao = 0.0;

    float z = texture2D(depthtex0, texCoord.xy).r;
    #ifdef VOXY
    float vxZ = texture2D(vxDepthTexOpaque, texCoord.xy).r;
    #endif
    #ifdef DISTANT_HORIZONS
    float dhZ = texture2D(dhDepthTex0, texCoord.xy).r;
    #endif

    if (z < 1.0) {
        ao = calculateAO(z, depthtex0, gbufferProjectionInverse, near, far, 0.25, false);
    #ifdef VOXY
    } else if (vxZ < 1.0) {
        const float vxNear = 16.0;
        const float vxFar = 48000.0;
        ao = calculateAO(vxZ, vxDepthTexOpaque, vxProjInv, vxNear, vxFar, 0.25, true);
    #endif
    #ifdef DISTANT_HORIZONS
    } else if (dhZ < 1.0) {
        ao = calculateAO(dhZ, dhDepthTex0, dhProjectionInverse, dhNearPlane, dhFarPlane, 0.25, true);
    #endif
    }

	/* DRAWBUFFERS:5 */
    gl_FragData[0].g = ao;
}

#endif

//**//**//**//**//**//**//**//**//**//**//**//**//**//**//

#ifdef VSH

// VSH Data //
out vec2 texCoord;

// Main //
void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}

#endif