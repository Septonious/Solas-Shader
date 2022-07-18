//Settings//
#include "/lib/common.glsl"

#ifdef FSH

const bool shadowHardwareFiltering = true;
const float shadowDistanceRenderMul = 1.0;
const int noiseTextureResolution = 256;
const float wetnessHalflife = 128.0;

//Optifine Constants//
/*
const int colortex0Format = RGBA16; //scene
const int colortex1Format = RGBA16; //translucent
const int colortex2Format = RGBA16; //normals, emissives, specular
const int colortex3Format = RGBA16; //vc
const int colortex4Format = RGBA16; //ao, vc
const int colortex5Format = RGBA16; //temporal data
const int colortex6Format = RGBA16; //reflection color
const int colortex7Format = RGBA16; //bloom color, used for bloom based colored lighting :tm: :tatsu_approves:
*/

//Varyings//
in vec2 texCoord;

//Uniforms//
uniform sampler2D colortex0;

#ifdef SHARPENING
uniform float viewWidth, viewHeight;
#endif

#ifdef CHROMATIC_ABERRATION
uniform float aspectRatio;
#endif

//Includes//
#ifdef SHARPENING
#include "/lib/post/sharpenFilter.glsl"
#endif

#ifdef CHROMATIC_ABERRATION
#include "/lib/post/chromaticAberration.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef SHARPENING
	sharpenFilter(colortex0, color, texCoord);
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