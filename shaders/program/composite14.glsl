//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_14

#ifdef FSH

//Varyings//
varying vec2 texCoord;

#ifdef LENS_FLARE
varying vec3 sunVec, upVec;
#endif

//Uniforms//
uniform float viewWidth, viewHeight;

#if defined BLOOM || defined LENS_FLARE
uniform float aspectRatio;
#endif

#ifdef LENS_FLARE
uniform float blindFactor, rainStrength;
uniform float timeAngle, timeBrightness;

uniform vec3 sunPosition;
uniform mat4 gbufferProjection;

uniform sampler2D depthtex0;
#endif

#ifdef TAA
uniform sampler2D colortex3;
#endif

uniform sampler2D colortex0;

#ifdef BLOOM
uniform sampler2D colortex1;
#endif

#ifdef TAA
const bool colortex3Clear = false;
#endif

//Common Variables//
#ifdef LENS_FLARE
float sunVisibility  = clamp((dot( sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
#endif

//Common Functions//
float GetLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

#ifdef LENS_FLARE
vec2 GetLightPos() {
	vec4 tpos = gbufferProjection * vec4(sunPosition, 1.0);
	tpos.xyz /= tpos.w;
	
	return tpos.xy / tpos.z * 0.5;
}
#endif

//Includes//
#include "/lib/post/tonemap.glsl"

#ifdef BLOOM
#include "/lib/post/getBloom.glsl"
#endif

#ifdef LENS_FLARE
#include "/lib/post/lensFlare.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef BLOOM
	getBloom(color, texCoord);
	#endif

	BSLTonemap(color);
	ColorSaturation(color);

	#ifdef LENS_FLARE
	vec2 lightPos = GetLightPos();
	float truePos = sign(sunVec.z);
	      
    float visibility = float(texture2D(depthtex0, lightPos + 0.5).r >= 1.0);
	visibility *= (1.0 - blindFactor) * (1.0 - rainStrength);

	if (visibility > 0.01) LensFlare(color, lightPos, truePos, 0.75 * visibility);
	#endif

	#ifdef TAA
	vec3 temporalColor = texture2D(colortex3, texCoord).gba;
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;

	#ifdef TAA
	/* DRAWBUFFERS:03 */
	gl_FragData[1].gba = temporalColor;
	#endif
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
varying vec2 texCoord;

#ifdef LENS_FLARE
varying vec3 sunVec, upVec;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();

	#ifdef LENS_FLARE
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
	#endif
}

#endif