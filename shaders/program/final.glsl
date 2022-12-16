//Settings//
#include "/lib/common.glsl"

#ifdef FSH

const bool shadowHardwareFiltering = true;
const float shadowDistanceRenderMul = 1.0;
const int noiseTextureResolution = 256;
const float wetnessHalflife = 128.0;

//Optifine Constants//
/*
const int colortex0Format = R11F_G11F_B10F; //scene
const int colortex1Format = RGB8; //translucent
const int colortex2Format = RGBA16; //normals, emissives, specular
const int colortex4Format = RGBA8; //ao
const int colortex5Format = RGBA16; //temporal data
const int colortex6Format = RGB10_A2; //reflection color
*/

//Varyings//
in vec2 texCoord;

//Uniforms//
uniform sampler2D colortex1;

#ifdef SHARPENING
uniform float viewWidth, viewHeight;
#endif

#ifdef CHROMATIC_ABERRATION
uniform float aspectRatio;
#endif

//Includes//
#if defined SHARPENING && MC_VERSION >= 11200
#include "/lib/post/sharpenFilter.glsl"
#endif

#ifdef CHROMATIC_ABERRATION
#include "/lib/post/chromaticAberration.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex1, texCoord).rgb;

	#if defined SHARPENING && MC_VERSION >= 11200
	sharpenFilter(color, texCoord);
	#endif

	#ifdef CHROMATIC_ABERRATION
	getChromaticAberration(color, texCoord);
	#endif

	gl_FragColor.rgb = color;
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