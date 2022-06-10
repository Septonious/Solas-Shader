//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_FINAL

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
uniform sampler2D colortex0;

uniform float viewWidth, viewHeight;
uniform float aspectRatio;

const bool shadowHardwareFiltering = true;
const float shadowDistanceRenderMul = 1.0;
const int noiseTextureResolution = 512;
const float drynessHalflife = 150.0;
const float wetnessHalflife = 300.0;

//Optifine Constants//
/*
const int colortex0Format = RGBA16; //scene
const int colortex1Format = RGBA16; //raw translucent, bloom, vl
const int colortex2Format = RGBA16; //water data
const int colortex3Format = RGBA16; //taa
const int colortex4Format = RGBA16; //vclouds
const int colortex5Format = RGBA16; //reflection image
const int colortex6Format = RGBA16; //normals
const int colortex7Format = RGBA16; //sspt
*/

//Includes//
#include "/lib/filters/sharpen.glsl"

#ifdef CHROMATIC_ABERRATION
#include "/lib/post/chromaticAberration.glsl"
#endif

//Program//
void main() {
	vec4 color = texture2D(colortex0, texCoord);
	sharpenFilter(color, texCoord, colortex0, MC_RENDER_QUALITY);

	#ifdef CHROMATIC_ABERRATION
	getChromaticAberration(color.rgb, texCoord);
	#endif

	gl_FragColor = color + Bayer256(gl_FragCoord.xy) / 256.0;
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
out vec2 texCoord;

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	gl_Position = ftransform();
}

#endif