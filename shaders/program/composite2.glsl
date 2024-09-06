//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_1

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef GI
uniform float viewWidth, viewHeight;

uniform vec3 cameraPosition, previousCameraPosition;

uniform sampler2D colortex4;
uniform sampler2D colortex5;
#endif

uniform sampler2D colortex0;

#ifdef GI
uniform sampler2D depthtex0;

uniform mat4 gbufferPreviousProjection, gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView, gbufferModelViewInverse;
#endif

//Includes//
#ifdef GI
#include "/lib/util/reprojection.glsl"
#include "/lib/filters/temporalAccumulation.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef GI
    float z0 = texture2D(depthtex0, texCoord).r;
	vec3 gi = texture2D(colortex4, texCoord).rgb;
    vec4 previousColor = vec4(texture2DLod(colortex5, texCoord, 0).r, 0.0, 0.0, 0.0);
	     previousColor = getTemporalAccumulation(gi, colortex5, previousColor.r, z0);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;

    #ifdef GI
    /* DRAWBUFFERS:045 */
	gl_FragData[1].rgb = pow(gi / 128.0, vec3(0.25));
    gl_FragData[2] = previousColor;
    #endif
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

//Program//
void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}

#endif