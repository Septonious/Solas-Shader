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

uniform sampler2D depthtex0, colortex0;

#ifdef BLOOM
uniform mat4 gbufferProjectionInverse;

uniform sampler2D colortex1;
#endif

#ifdef TAA
uniform sampler2D colortex5;
#endif

//Optifine Constants//
#ifdef BLOOM
const bool colortex4Clear = false;
#endif

#ifdef TAA
const bool colortex5Clear = false;
#endif

//Common Functions//
#ifdef BLOOMY_FOG
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

#ifdef BLOOMY_FOG
#include "/lib/util/ToView.glsl"
#endif
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;
	vec3 tempData = vec3(0.0);
	vec3 rawBloom = vec3(0.0);

	float dither = Bayer64(gl_FragCoord.xy);
	float z0 = texture2D(depthtex0, texCoord).r;

	#ifdef BLOOM
	rawBloom = getBloom(texCoord, dither - 0.25, z0);

	#if BLOOM_CONTRAST == 0
	color = mix(color, rawBloom, 0.025 * BLOOM_STRENGTH);
	#else
	vec3 bloomContrast = vec3(exp2(BLOOM_CONTRAST * 0.25));
	color = pow(color, bloomContrast);

	vec3 bloomStrength = pow(vec3(0.025 * BLOOM_STRENGTH), bloomContrast);
	color = mix(color, pow(rawBloom, bloomContrast), bloomStrength);
	color = pow(color, 1.0 / bloomContrast);
	#endif

	#ifdef BLOOMY_FOG
	vec3 viewPos = ToView(vec3(texCoord, z0));
	float fog = length(viewPos) * FOG_DENSITY * 0.001;
		  fog = 1.0 - exp(-4.0 * fog);

	vec3 bloomFog = clamp(0.0625 * rawBloom * pow(getLuminance(rawBloom), -0.5) * fog, 0.0, 1.0) * 16.0;

	#ifdef NETHER
	bloomFog *= 4.0;
	#endif

	color += bloomFog * 0.05;
	#endif
	#endif

	#ifdef TAA
	tempData = texture2D(colortex5, texCoord).gba;
	#endif

	BSLTonemap(color);
	color = pow(color, vec3(1.0 / 2.2));
	ColorSaturation(color);

	color += (dither - 0.25) / 64.0;

	/* DRAWBUFFERS:154 */
	gl_FragData[0].rgb = color;
	gl_FragData[1].gba = tempData;
	gl_FragData[2].rgb = pow(rawBloom / 128.0, vec3(0.25)) * float(z0 < 1.0);
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