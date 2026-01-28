#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
uniform sampler2D colortex1;

uniform float viewWidth, viewHeight;

#ifdef CHROMATIC_ABERRATION
uniform float aspectRatio;
#endif

#ifdef NETHER
uniform sampler2D shadowtex0;
#endif

// Pipeline Options //
const bool shadowHardwareFiltering = false;
const int noiseTextureResolution = 512;
const float shadowDistanceRenderMul = 1.0;
const float drynessHalflife = 300.0;
const float wetnessHalflife = 300.0;
const float eyeBrightnessHalflife = 5.0;

/*
const int colortex0Format = R11F_G11F_B10F; //GB scene
const int colortex1Format = RGB16F; //Final scene
const int colortex3Format = RGBA16; //PBR data
const int colortex4Format = RGB8; //Reflections
*/

// Includes //
#if MC_VERSION >= 11200
#include "/lib/post/sharpenFilter.glsl"
#endif

#ifdef CHROMATIC_ABERRATION
#include "/lib/post/chromaticAberration.glsl"
#endif

// Main //
void main() {
    vec3 color = texture2D(colortex1, texCoord).rgb;

	#if MC_VERSION >= 11200
	sharpenFilter(color, texCoord);
	#endif

	#ifdef CHROMATIC_ABERRATION
	getChromaticAberration(colortex1, color, texCoord);
	#endif

	#if defined NETHER && defined VX_SUPPORT
	if (texCoord.x < 0.0) {
		color = texture2D(shadowtex0, texCoord).rgb;
	}
	#endif

    gl_FragColor.rgb = color;
}

#endif


//**//**//**//**//**//**//**//**//**//**//**//**//**//**//


#ifdef VSH

// VSH Data //
out vec2 texCoord;

// Main //
void main() {
    texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();
}

#endif