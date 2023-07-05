//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef BLOOM
uniform float viewWidth, viewHeight, aspectRatio;
#endif

uniform sampler2D colortex0;

//Optifine Constants//
#ifdef BLOOM
const bool colortex0MipmapEnabled = true;
#endif

//Includes//
#ifdef BLOOM
#include "/lib/post/computeBloom.glsl"
#endif

void main() {
	vec3 blur = vec3(0.0);

	#ifdef BLOOM
	blur = computeBloom(texCoord);
	#endif

	/* DRAWBUFFERS:1 */
	gl_FragData[0].rgb = blur;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}

#endif