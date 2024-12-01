//Settings//
#include "/lib/common.glsl"

#ifdef FSH

const int noiseTextureResolution = 512;
const float shadowDistanceRenderMul = 1.0;
const float wetnessHalflife = 128.0;

//Buffer Options//
/*
const int colortex0Format = R11F_G11F_B10F; //Main Scene
const int colortex1Format = RGBA16; //Main Scene, Translucent
const int colortex2Format = RGBA16; //Temporal data
const int colortex3Format = RGBA16; //gbuffers data
const int colortex4Format = RGB8; //rsm gi
const int colortex5Format = RGBA16; //accumulated rsm
const int colortex6Format = RGBA16; //reflections
const int colortex7Format = RGBA16; //skybox
*/

const bool colortex0Clear = false;
const bool colortex1Clear = false;
const bool colortex3Clear = false;
const bool colortex4Clear = false;
const bool gaux1Clear = false;

//Varyings//
in vec2 texCoord;

//Uniforms//
uniform sampler2D colortex1;
uniform sampler2D shadowtex0;

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
	getChromaticAberration(colortex1, color, texCoord);
	#endif

	if (texCoord.x < 0.0) {
		color = texture2D(shadowtex0, texCoord).rgb;
	}

	#ifndef DRM_S0L4S
	color *= color * 19.84;
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