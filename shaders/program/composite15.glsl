//Settings//
#include "/lib/common.glsl"

#define COMPOSITE_14

#ifdef FSH

//Varyings//
in vec2 texCoord;

#ifdef LENS_FLARE
in vec3 sunVec, upVec;
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

#if defined TAA || defined LENS_FLARE
uniform sampler2D colortex3;
#endif

uniform sampler2D colortex0;

#ifdef BLOOM
uniform sampler2D colortex1;
#endif

#if defined TAA || defined LENS_FLARE
const bool colortex3Clear = false;
#endif

//Common Variables//
#ifdef LENS_FLARE
float sunVisibility  = clamp((dot( sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
#endif

float pixelWidth = 1.0 / viewWidth;
float pixelHeight = 1.0 / viewHeight;

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
	vec3 temporalColor = vec3(0.0);
	float temporalData = 0.0;

	#ifdef BLOOM
	getBloom(color, texCoord);
	#endif

	BSLTonemap(color);
	ColorSaturation(color);

	#ifdef LENS_FLARE
	vec2 lightPos = GetLightPos();
	float truePos = sign(sunVec.z);
	float tempVisibleSun = texture2D(colortex3, vec2(3.0 * pixelWidth, pixelHeight)).r;
	      
    float visibleSun = float(texture2D(depthtex0, lightPos + 0.5).r >= 1.0);
	visibleSun *= (1.0 - blindFactor) * (1.0 - rainStrength);

	if (visibleSun > 0.001) LensFlare(color, lightPos, truePos, 0.65 * tempVisibleSun);
	if (texCoord.x > 2.0 * pixelWidth && texCoord.x < 4.0 * pixelWidth && texCoord.y < 2.0 * pixelHeight)
		temporalData = mix(tempVisibleSun, visibleSun, 0.125);
	#endif

	#ifdef TAA
	temporalColor = texture2D(colortex3, texCoord).gba;
	#endif

	/* DRAWBUFFERS:03 */
	gl_FragData[0].rgb = color;
	gl_FragData[1] = vec4(temporalData, temporalColor);
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

#ifdef LENS_FLARE
out vec3 sunVec, upVec;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
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