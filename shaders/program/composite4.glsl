//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef COLORED_LIGHTING
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
#endif

uniform sampler2D colortex0;

#ifdef COLORED_LIGHTING
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView, gbufferPreviousProjection;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
#endif

//Optifine Constants//
const bool colortex4Clear = false;

//Includes//
#ifdef COLORED_LIGHTING
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/reprojection.glsl"
#include "/lib/lighting/coloredLighting.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	vec3 coloredLighting = vec3(0.0);
	
	#ifdef COLORED_LIGHTING
	float z0 = texture2D(depthtex0, texCoord).r;

	computeColoredLighting(z0, coloredLighting);
	#endif

	/* DRAWBUFFERS:04 */
	gl_FragData[0].rgb = color;
	gl_FragData[1].rgb = coloredLighting;
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