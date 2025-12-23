#define OVERWORLD
#define VOXY_OPAQUE

#include "/lib/common.glsl"

// Global Variables //
#if defined OVERWORLD
const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
float fractTimeAngle = fract(timeAngle - 0.25);
float ang = (fractTimeAngle + (cos(fractTimeAngle * 3.14159265358979) * -0.5 + 0.5 - fractTimeAngle) / 3.0) * 6.28318530717959;
vec3 sunVec = normalize((vxModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
#elif defined END
const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
vec3 sunVec = normalize((vxModelView * vec4(1.0, sunRotationData * 2000.0, 1.0)).xyz);
#else
vec3 sunVec = vec3(0.0);
#endif

vec3 upVec = normalize(vxModelView[1].xyz);
vec3 eastVec = normalize(vxModelView[0].xyz);

#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = fmix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, sqrt(eBS));
float sunVisibility = clamp((dot( sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#endif

// Includes //
#include "/lib/util/transformMacros.glsl"
#include "/lib/util/ToNDCVoxy.glsl"
#include "/lib/util/ToWorldVoxy.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/pbr/ggx.glsl"
#include "/lib/lighting/shadowsVoxy.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/lighting/lightning.glsl"

#ifdef VC_SHADOWS
#include "/lib/lighting/cloudShadows.glsl"
#endif

#include "/lib/lighting/gbuffersLighting.glsl"

#if defined GENERATED_EMISSION || defined GENERATED_SPECULAR
#include "/lib/pbr/generatedPBR.glsl"
#endif

layout(location = 0) out vec4 out0;

// Main //
void voxy_emitFragment(VoxyFragmentParameters parameters) {
    vec4 albedoTexture = parameters.sampledColour;
    vec4 voxyColor = parameters.tinting;
    vec4 albedo = albedoTexture * vec4(voxyColor.rgb, 1.0);
    vec2 lightmap = clamp((parameters.lightMap - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    vec3 viewPos = ToNDC(screenPos);
    vec3 worldPos = ToWorld(viewPos);
    vec3 normal = vec3(0.0);

    switch (uint(parameters.face) >> 1u) {
        case 0u:
        normal = vxModelView[1].xyz;
        break;
        case 1u:
        normal = vxModelView[2].xyz;
        break;
        case 2u:
        normal = vxModelView[0].xyz;
        break;
    }
    if ((parameters.face & 1) == 0) {
        normal = -normal;
    }

    vec3 newNormal = normal;

    int mat = int(parameters.customId);
	float leaves = float(mat == 10314);
	float saplings = float(mat == 10317);
	float foliage = float(mat >= 10304 && mat <= 10319 || mat >= 10035 && mat <= 10040) * (1.0 - leaves) * (1.0 - saplings);
	float subsurface = leaves + foliage * 0.6 + saplings * 0.4;
    float emission = 0.0;
    float smoothness = 0.0;
    float metalness = 0.0;

	float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
    #if defined OVERWORLD
	float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
    #elif defined END
    float NoL = clamp(dot(newNormal, sunVec), 0.0, 1.0);
    #else
    float NoL = 0.0;
    #endif
	float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);
    
	#if defined GENERATED_EMISSION || defined GENERATED_SPECULAR
	generateIPBR(albedo, worldPos, viewPos, lightmap, NoU, emission, smoothness, metalness, subsurface, mat);
	#endif

    float parallaxShadow = 1.0;
    vec3 shadow = vec3(0.0);
    gbuffersLighting(voxyColor, albedo, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, subsurface, emission, smoothness, parallaxShadow);

    out0 = albedo;
}
#undef VOXY_OPAQUE