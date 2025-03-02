//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef BLOOM
#ifdef TAA
uniform int frameTimeCounter;
#endif

uniform float viewWidth, viewHeight;

#ifdef OVERWORLD
uniform float timeBrightness;
#endif
#endif

uniform ivec2 eyeBrightnessSmooth;

uniform sampler2D colortex0;
uniform sampler2D colortex2;

#ifdef BLOOM
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
#endif

//Optifine Constants//
const bool colortex1MipmapEnabled = true;

#ifdef TAA
const bool colortex2Clear = false;
const bool colortex2MipmapEnabled = true;
#endif

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;

//Includes//
#include "/lib/util/bayerDithering.glsl"
#include "/lib/post/tonemap.glsl"

#ifdef BLOOM
#include "/lib/post/getBloom.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef TAA
	vec3 temporalColor = texture2DLod(colortex2, texCoord, 0).gba;
	#endif

	#ifdef BLOOM
    float z0 = texture2D(depthtex0, texCoord).r;
	getBloom(color, texCoord, z0);
	#endif

	vec3 curr = Uncharted2Tonemap(color * TONEMAP_BRIGHTNESS);

	color = pow(curr / Uncharted2Tonemap(vec3(TONEMAP_WHITE_THRESHOLD)), vec3(1.0 / 2.2));

	/* DRAWBUFFERS:1 */
	gl_FragData[0].rgb = color;

    #ifdef TAA
    /* DRAWBUFFERS:12 */
	gl_FragData[1].gba = temporalColor;
    #endif
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

#include "/lib/wmark/s0las_shader.glsl"

//Varyings//
out vec2 texCoord;

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy * float(chval == 0.1984);

	//Position
	gl_Position = ftransform();
}

#endif