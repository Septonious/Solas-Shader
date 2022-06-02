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
const float drynessHalflife = 50.0;
const float wetnessHalflife = 300.0;
const bool colortex5Clear = false;

//Optifine Constants//
/*
const int colortex0Format = RGBA16; //scene
const int colortex0Format = RGBA16; //raw translucent, bloom, vl
const int colortex2Format = RGBA16; //water data
const int colortex3Format = RGBA16; //taa
const int colortex4Format = RGBA16; //vclouds
const int colortex5Format = RGBA16; //normals
const int colortex6Format = RGBA16; //sspt
const int colortex7Format = RGBA16; //reflection image
*/

//Common Functions//
vec2 sharpenOffsets[4] = vec2[4](
	vec2( 1.0,  0.0),
	vec2( 0.0,  1.0),
	vec2(-1.0,  0.0),
	vec2( 0.0, -1.0)
);

void sharpenFilter(inout vec3 color, vec2 coord) {
	float mult = MC_RENDER_QUALITY * 0.0625;
	vec2 view = 1.0 / vec2(viewWidth, viewHeight);

	color *= MC_RENDER_QUALITY * 0.25 + 1.0;

	for(int i = 0; i < 4; i++) {
		vec2 offset = sharpenOffsets[i] * view;
		color -= texture2D(colortex0, coord + offset).rgb * mult;
	}
}

//Includes//
#ifdef CHROMATIC_ABERRATION
#include "/lib/post/chromaticAberration.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;
	sharpenFilter(color, texCoord);

	#ifdef CHROMATIC_ABERRATION
	getChromaticAberration(color, texCoord);
	#endif

	gl_FragColor.rgb = color + Bayer256(gl_FragCoord.xy) / 256.0;
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