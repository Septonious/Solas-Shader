//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#if defined COLORED_LIGHTING || defined GI
uniform int frameCounter;

uniform float far, near;
uniform float aspectRatio;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform sampler2D depthtex0;
uniform sampler2D colortex3;

#ifdef COLORED_LIGHTING
uniform sampler2D colortex4;
#endif

#ifdef GI
uniform sampler2D colortex5;
#endif
#endif

uniform sampler2D colortex0;

#if defined COLORED_LIGHTING || defined GI
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView, gbufferPreviousProjection;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
#endif

//Optifine Constants//
const bool colortex4Clear = false;
const bool colortex5Clear = false;

//Includes//
#if defined COLORED_LIGHTING || defined GI
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/reprojection.glsl"
#include "/lib/lighting/coloredLighting.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	vec3 coloredLighting = vec3(0.0);
	vec3 globalIllumination = vec3(0.0);

	#if defined COLORED_LIGHTING || defined GI
	float z0 = texture2D(depthtex0, texCoord).r;

	computeColoredLighting(z0, coloredLighting, globalIllumination);
	#endif

	/* DRAWBUFFERS:045 */
	gl_FragData[0].rgb = color;
	gl_FragData[1].rgb = coloredLighting;
	gl_FragData[2].rgb = globalIllumination;
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