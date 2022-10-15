//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef TAA
uniform int frameCounter;
#endif

#if defined TAA || defined FXAA || defined DOF
uniform float viewWidth, viewHeight;
#endif

#if defined DOF || defined FXAA
uniform float aspectRatio;
#endif

#ifdef DOF
uniform float centerDepthSmooth;
#endif

#ifdef TAA
uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferPreviousProjection, gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView, gbufferModelViewInverse;

uniform sampler2D colortex5;
#endif

#if defined TAA || defined DOF
#ifdef DOF
uniform mat4 gbufferProjection;

uniform sampler2D depthtex0;
#endif

uniform sampler2D depthtex1;
#endif

uniform sampler2D colortex1;

//Optifine Constants//
#ifdef DOF
const bool colortex0MipmapEnabled = true;
#endif

//Common Functions//
#ifdef FXAA
float getLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}
#endif

//Includes//
#ifdef DOF
#include "/lib/post/dofBlur.glsl"
#endif

#ifdef FXAA
#include "/lib/antialiasing/fxaa.glsl"
#endif

#ifdef TAA
#include "/lib/util/reprojection.glsl"
#include "/lib/antialiasing/taa.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex1, texCoord).rgb;

	#ifdef DOF
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	color = getDepthOfField(color, viewPos.xyz, z1);
	#endif

	#ifdef FXAA
	color = FXAA311(color);	
	#endif

	#ifdef TAA
    vec4 prev = vec4(texture2D(colortex5, texCoord).r, 0.0, 0.0, 0.0);
	prev = TemporalAA(color, prev.r, colortex1, colortex5);
	#endif

	/* DRAWBUFFERS:1 */
	gl_FragData[0].rgb = color;

	#ifdef TAA
	/* DRAWBUFFERS:15 */
	gl_FragData[1] = prev;
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