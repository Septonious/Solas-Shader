//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef TAA
uniform float viewWidth, viewHeight, aspectRatio;

uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView, gbufferModelViewInverse;
#endif

uniform sampler2D depthtex1;
uniform sampler2D colortex1, colortex2;

#ifdef TAA
uniform mat4 gbufferProjectionInverse;
#endif

//Optifine Constants//
const bool colortex1MipmapEnabled = true;

//Includes//
#ifdef TAA
#include "/lib/util/reprojection.glsl"
#include "/lib/antialiasing/taa.glsl"
#endif

//Program//
void main() {
	vec2 newTexCoord = texCoord;
	vec3 color = texture2DLod(colortex1, newTexCoord, 0).rgb;

	#ifdef TAA
	float z1 = texture2D(depthtex1, newTexCoord).r;
	#endif

	vec4 previousColor = vec4(texture2D(colortex2, newTexCoord).r, 0.0, 0.0, 0.0);
	#ifdef TAA
	     previousColor = TemporalAA(color, previousColor.r, z1);
	#endif

    /* DRAWBUFFERS:12 */
	gl_FragData[0] = vec4(color, 1.0);
	gl_FragData[1] = vec4(previousColor);
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