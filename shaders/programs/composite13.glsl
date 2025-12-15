#include "/lib/common.glsl"

#define COMPOSITE13

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
#ifdef BLOOM
uniform float viewWidth, viewHeight, aspectRatio;
#endif

uniform sampler2D colortex0;

// Pipeline Options //
#ifdef BLOOM
const bool colortex0MipmapEnabled = true;
#endif

// Includes //
#ifdef BLOOM
#include "/lib/util/bayerDithering.glsl"
#include "/lib/post/computeBloom.glsl"
#endif

// Main //
void main() {
	vec3 blur = vec3(0.0);

	#ifdef BLOOM
	blur = computeBloom(texCoord);
	#endif

	/* DRAWBUFFERS:1 */
	gl_FragData[0].rgb = blur;
}

#endif

//**//**//**//**//**//**//**//**//**//**//**//**//**//**//

#ifdef VSH

// VSH Data //
out vec2 texCoord;

void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
}

#endif