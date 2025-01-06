//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
uniform int frameCounter;

#if defined TAA || defined FXAA || defined DOF
uniform float viewWidth, viewHeight;
uniform float aspectRatio;

#ifdef MANUAL_FOCUS
uniform float far, near;
#endif
#endif

#ifdef DOF
#ifndef MANUAL_FOCUS
uniform float centerDepthSmooth;
#else
float centerDepthSmooth = ((DOF_FOCUS - near) * far) / ((far - near) * DOF_FOCUS);
#endif
#endif

#if defined TAA || defined MOTION_BLUR
uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView, gbufferModelViewInverse;

uniform sampler2D colortex2, colortex3;
#endif

uniform sampler2D depthtex1;
uniform sampler2D colortex1;

#if defined TAA || defined DOF
uniform mat4 gbufferProjectionInverse;

#ifdef DOF
uniform mat4 gbufferProjection;
#endif
#endif

//Optifine Constants//
const bool colortex1MipmapEnabled = true;
const bool colortex2MipmapEnabled = true;
const bool colortex3MipmapEnabled = true;

//Includes//
#ifdef DOF
#include "/lib/util/ToView.glsl"
#include "/lib/post/computeDOF.glsl"
#endif

#ifdef MOTION_BLUR
#include "/lib/util/bayerDithering.glsl"
#include "/lib/post/motionBlur.glsl"
#endif

#ifdef FXAA
#include "/lib/antialiasing/fxaa.glsl"
#endif

#ifdef TAA
#include "/lib/util/reprojection.glsl"
#include "/lib/antialiasing/taa.glsl"
#endif

void main() {
	vec2 newTexCoord = texCoord;

	#if defined DOF || defined TAA || defined MOTION_BLUR
	float z1 = texture2D(depthtex1, newTexCoord).r;
	#endif

    vec3 color = texture2DLod(colortex1, newTexCoord, 0).rgb;
	#ifdef FXAA
		 color = FXAA311(color);	
	#endif

	#ifdef MOTION_BLUR
		 color = getMotionBlur(color, z1);
	#endif

	#ifdef DOF
		 color = getDepthOfField(color, newTexCoord, z1);
	#endif

	#ifdef TAA
    vec4 previousColor = vec4(texture2DLod(colortex2, newTexCoord, 0).r, 0.0, 0.0, 0.0);
	     previousColor = TemporalAA(color, previousColor.r, z1);
	#endif

    /* DRAWBUFFERS:1 */
	gl_FragData[0].rgb = color;

    #ifdef TAA
    /* DRAWBUFFERS:12 */
	gl_FragData[1] = previousColor;
    #endif
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