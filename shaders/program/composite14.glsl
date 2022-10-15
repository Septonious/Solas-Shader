//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
uniform float viewWidth, viewHeight;

#if defined BLOOM && defined TAA
uniform float frameTimeCounter;
#endif

uniform sampler2D colortex0;

#ifdef BLOOM
uniform sampler2D depthtex0, colortex1;
#endif

#ifdef TAA
uniform sampler2D colortex5;
#endif

//Optifine Constants//
#ifdef BLOOM
const bool colortex7Clear = false;
#endif

#ifdef TAA
const bool colortex5Clear = false;
#endif

//Common Functions//
#ifdef BLOOM
float getLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}
#endif

//Includes//
#include "/lib/util/bayerDithering.glsl"
#include "/lib/post/tonemap.glsl"

#ifdef BLOOM
#include "/lib/filters/blur.glsl"
#include "/lib/post/getBloom.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;
	vec3 temporalColor = vec3(0.0);
	vec3 rawBloom = vec3(0.0);

	float dither = Bayer64(gl_FragCoord.xy);

	#ifdef BLOOM
	rawBloom = getBloom(texCoord, dither - 0.5);
	color = mix(color, rawBloom, BLOOM_STRENGTH * 0.1 + getLuminance(rawBloom) * 0.1);
	#endif

	#ifdef TAA
	temporalColor = texture2D(colortex5, texCoord).gba;
	#endif

	BSLTonemap(color);
	color = pow(color, vec3(1.0 / 2.2));
	ColorSaturation(color);

	color += (dither - 0.25) / 64.0;

	/* DRAWBUFFERS:157 */
	gl_FragData[0].rgb = color;
	gl_FragData[1].gba = temporalColor;
	gl_FragData[2].rgb = pow(rawBloom / 256.0, vec3(0.125));
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