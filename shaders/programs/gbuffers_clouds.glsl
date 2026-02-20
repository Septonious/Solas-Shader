#define GBUFFERS_CLOUDS

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec4 color;
in vec3 normal;
in vec2 texCoord;

// Uniforms //
uniform int isEyeInWater;
uniform int worldTime;

uniform float cloudHeight;
uniform float wetness;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;
uniform float blindFactor, nightVision;
#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform vec3 cameraPosition, skyColor;

uniform sampler2D texture;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

// Global Variables //
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

#ifdef OVERWORLD
float sunVisibility = clamp((dot( sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#endif

// Includes //
#include "/lib/util/transformMacros.glsl"
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/color/lightColor.glsl"

// Main //
void main() {
	#ifdef VANILLA_CLOUDS
		vec4 albedo = texture2D(texture, texCoord);

		if (albedo.a > 0.0) {
			albedo.a = VANILLA_CLOUD_OPACITY;
			albedo.a *= albedo.a;
		}

		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		vec3 viewPos = ToNDC(screenPos);
		vec3 worldPos = ToWorld(viewPos);
		vec3 nViewPos = normalize(viewPos);

		float cloudHeightFactor = clamp(worldPos.y + cameraPosition.y - cloudHeight - 0.5, 0.0, 4.0) * 0.25;
		albedo.rgb *= mix(ambientColSqrt * 0.65, lightColSqrt, cloudHeightFactor);

		float scattering = pow4(dot(normal, lightVec) * 0.5 + 0.5);
			scattering += pow7(dot(nViewPos, lightVec) * 0.5 + 0.5) * 0.5;
		albedo.rgb *= 1.0 + scattering * shadowFade * (1.0 - wetness * 0.5);

		#if VANILLA_CLOUD_FOG > 0
		#if VANILLA_CLOUD_FOG == 1
		float vanillaFogEnd = 4.0;
		#elif VANILLA_CLOUD_FOG == 2
		float vanillaFogEnd = 2.0;
		#else
		float vanillaFogEnd = 1.0;
		#endif

		float worldDistance = length(worldPos.xz) / 256.0;
		float vanillaFog = 1.0 - smoothstep(0.5, vanillaFogEnd, worldDistance);

		albedo.a *= color.a * vanillaFog;
		#endif

		albedo *= 1.0 - blindFactor;
		#if MC_VERSION >= 11900
		albedo *= 1.0 - darknessFactor;
		#endif
	#else
		vec4 albedo = vec4(0.0);
	#endif
	
    /* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}

#endif


//**//**//**//**//**//**//**//**//**//**//**//**//**//**//


#ifdef VSH

// VSH Data //
out vec4 color;
out vec3 normal;
out vec2 texCoord;

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	color = gl_Color;

	normal = normalize(gl_NormalMatrix * gl_Normal);
	
	gl_Position = ftransform();
}

#endif