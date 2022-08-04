//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef TAA
uniform int frameCounter;
#endif

#if defined TAA || defined FXAA
uniform float viewWidth, viewHeight;
#endif

#ifdef FXAA
uniform float aspectRatio;
#endif

uniform sampler2D colortex1;

#ifdef TAA
uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferPreviousProjection, gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView, gbufferModelViewInverse;

uniform sampler2D colortex5;
uniform sampler2D depthtex1;
#endif

//Common Functions//
#ifdef FXAA
float getLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}
#endif

//Includes//
#ifdef FXAA
#include "/lib/antialiasing/fxaa.glsl"
#endif

#ifdef TAA
#include "/lib/util/reprojection.glsl"
#include "/lib/antialiasing/taa.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex1, texCoord).rgb;

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