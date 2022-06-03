//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_3

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef SSPT
uniform int frameCounter;

uniform float viewWidth, viewHeight;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform sampler2D depthtex2;
uniform sampler2D colortex6;
uniform sampler2D depthtex0, depthtex1;
#endif

uniform sampler2D colortex0;

//Includes//
#ifdef SSPT
#include "/lib/util/encode.glsl"
#include "/lib/util/blueNoise.glsl"
#include "/lib/lighting/sspt.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef SSPT
    float z0 = texture2D(depthtex0, texCoord).x;

	vec3 screenPos = vec3(texCoord, z0);
    vec3 normal = normalize(DecodeNormal(texture2D(colortex6, texCoord).xy));
    vec3 sspt = computeSSPT(screenPos, normal, float(z0 < 0.56));
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;

	#ifdef SSPT
	/* DRAWBUFFERS:07 */
	gl_FragData[1].rgb = sspt;
	#endif
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	gl_Position = ftransform();
}

#endif
