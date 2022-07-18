//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef TAA
uniform int frameCounter;

uniform float viewWidth, viewHeight;
#endif

uniform sampler2D colortex0;

#ifdef TAA
uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferPreviousProjection, gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView, gbufferModelViewInverse;

uniform sampler2D colortex5;
uniform sampler2D depthtex1;
#endif

//Includes//
#ifdef TAA
#include "/lib/util/reprojection.glsl"
#include "/lib/antialiasing/taa.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef TAA
    vec4 prev = vec4(texture2D(colortex5, texCoord).r, 0.0, 0.0, 0.0);
	prev = TemporalAA(color, prev.r, colortex0, colortex5);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;

	#ifdef TAA
	/* DRAWBUFFERS:05 */
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