#define COMPOSITE_4

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// Varyings //
in vec2 texCoord;

// Uniforms //
#ifdef WATER_FOG
uniform int isEyeInWater;

#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform float frameTimeCounter;
uniform float blindFactor;
uniform float timeBrightness, timeAngle, wetness, shadowFade;
uniform float eyeAltitude;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 fogColor;
#endif

uniform sampler2D colortex0;

#ifdef WATER_FOG
uniform sampler2D depthtex0, depthtex1;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
#endif

// Global Variables //
#ifdef WATER_FOG
#if defined OVERWORLD
const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
float fractTimeAngle = fract(timeAngle - 0.25);
float ang = (fractTimeAngle + (cos(fractTimeAngle * 3.14159265358979) * -0.5 + 0.5 - fractTimeAngle) / 3.0) * 6.28318530717959;
vec3 sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
#elif defined END
const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
vec3 sunVec = normalize((gbufferModelView * vec4(1.0, sunRotationData * 2000.0, 1.0)).xyz);
#else
vec3 sunVec = vec3(0.0);
#endif

vec3 upVec = normalize(gbufferModelView[1].xyz);

float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((eyeAltitude - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, sqrt(eBS));
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
#endif

// Includes //
#ifdef WATER_FOG
#include "/lib/util/ToView.glsl"
#include "/lib/water/waterFog.glsl"
#endif

// Main //
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;
		 color = pow(color, vec3(2.2));

	#ifdef WATER_FOG
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;
	
	vec3 screenPos = vec3(texCoord, z0);
	vec3 viewPos = ToView(screenPos);

	if (isEyeInWater == 1){
		vec3 colorMult = vec3(1.0);
		vec4 waterFog = getWaterFog(colorMult, viewPos);
		color *= colorMult;
		color = mix(sqrt(color), sqrt(waterFog.rgb), waterFog.a);
		color *= color;
	}
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;
}

#endif

//**//**//**//**//**//**//**//**//**//**//**//**//**//**//

#ifdef VSH

// Varyings //
out vec2 texCoord;

// Main //
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}

#endif