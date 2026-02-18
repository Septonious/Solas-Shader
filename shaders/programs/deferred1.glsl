#define DEFERRED

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
uniform int dhRenderDistance, vxRenderDistance;
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef OVERWORLD
uniform int worldDay;
uniform int moonPhase;
uniform int worldTime;

uniform float shadowFade;
uniform float rainStrength;
uniform float timeAngle, timeBrightness, wetness;

#if MC_VERSION >= 12104
uniform float isPaleGarden;
#endif

uniform vec3 skyColor;
#endif

uniform float viewWidth, viewHeight;
uniform float far, near;
#ifdef DISTANT_HORIZONS
uniform float dhFarPlane;
#endif
uniform float blindFactor, nightVision;
#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform float frameTimeCounter;

uniform ivec2 eyeBrightnessSmooth;

#if defined END && MC_VERSION >= 12100
uniform float endFlashIntensity;

uniform vec3 endFlashPosition;
#endif

uniform vec3 cameraPosition;

#ifdef NETHER
uniform vec3 fogColor;
#endif

#ifdef VOLUMETRIC_CLOUDS
uniform vec4 lightningBoltPosition;
#endif

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
#ifdef DISTANT_HORIZONS
uniform sampler2D dhDepthTex0;
#endif
#ifdef VOXY
uniform sampler2D vxDepthTexOpaque;
#endif

#ifdef SS_SHADOWS
uniform sampler2D colortex3;
#endif

uniform sampler2D noisetex;

#ifdef SSAO
uniform sampler2D colortex5;
#endif

#ifdef MILKY_WAY
uniform sampler2D depthtex2;
#endif

#if defined VOLUMETRIC_CLOUDS || defined END_DISK
uniform sampler2D shadowtex1;

uniform mat4 shadowModelView, shadowProjection;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

#ifdef DISTANT_HORIZONS
uniform mat4 dhProjection, dhProjectionInverse;
#endif

#ifdef VOXY
uniform mat4 vxProj, vxProjInv, vxModelViewInv;
#endif

// Pipeline Options //
const bool colortex4Clear = false;
const bool colortex5Clear = false;

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
vec3 eastVec = normalize(gbufferModelView[0].xyz);

#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = fmix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, sqrt(eBS));
float sunVisibility = clamp((dot( sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
vec3 lightVec = sunVec;
#endif

#ifdef VOXY
vec3 ToWorldVoxy(vec3 viewPos) {
    return mat3(vxModelViewInv) * viewPos + vxModelViewInv[3].xyz;
}
#endif

// Includes //
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/color/lightColor.glsl"

#ifdef SSAO
#include "/lib/lighting/ambientOcclusion.glsl"
#endif

#ifdef SS_SHADOWS
#include "/lib/lighting/screenSpaceShadows.glsl"
#endif

#ifdef OVERWORLD
#include "/lib/atmosphere/sky.glsl"

#ifdef ROUND_SUN_MOON
#include "/lib/atmosphere/sunMoon.glsl"
#endif
#endif

#if defined VOLUMETRIC_CLOUDS || defined END_DISK
#include "/lib/atmosphere/spaceConversion.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/lighting/lightning.glsl"
#include "/lib/atmosphere/volumetricClouds.glsl"
#endif

#include "/lib/atmosphere/skyEffects.glsl"
#include "/lib/atmosphere/fog.glsl"

// Main //
void main() {
    vec3 color = texture2D(colortex0, texCoord).rgb;

    float z0 = texture2D(depthtex0, texCoord).r;
	#ifdef DISTANT_HORIZONS
	float dhZ0 = texture2D(dhDepthTex0, texCoord).r;
	#endif
    #ifdef VOXY
    float vxZ0 = texture2D(vxDepthTexOpaque, texCoord).r;
    #endif

	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		    viewPos /= viewPos.w;
	vec4 worldPos = gbufferModelViewInverse * vec4(viewPos.xyz, 1.0);
		    worldPos.xyz /= worldPos.w;

    float atmosphereHardMixFactor = 0.0;

    #if defined OVERWORLD
    vec3 atmosphereColor = getAtmosphere(viewPos.xyz, worldPos.xyz, atmosphereHardMixFactor);
	#elif defined NETHER
	vec3 atmosphereColor = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 atmosphereColor = endAmbientColSqrt * 0.175;
	#endif

	#if defined OVERWORLD || defined END
	vec3 nViewPos = normalize(viewPos.xyz);

	float VoU = dot(nViewPos, upVec);
	float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
	float VoM = clamp(dot(nViewPos, -sunVec), 0.0, 1.0);
	#endif

    //Volumetric Clouds
	vec4 vc = vec4(0.0);

	#ifdef DISTANT_HORIZONS
	float cloudDepth = 2.0 * dhFarPlane;
	#else
	float cloudDepth = 2.0 * far;
	#endif

	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;
	#ifdef TAA
	      blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif
	
	#ifdef VOLUMETRIC_CLOUDS
	computeVolumetricClouds(vc, atmosphereColor, z0, blueNoiseDither, cloudDepth);
	#endif

	#ifdef END_DISK
	computeEndVolumetricClouds(vc, atmosphereColor, z0, blueNoiseDither, cloudDepth);
	#endif

    float occlusion = vc.a;

    //Planar Clouds
    vec4 pc = vec4(0.0);

    #ifdef PLANAR_CLOUDS
    drawPlanarClouds(pc, atmosphereColor, worldPos.xyz, viewPos.xyz, VoU, caveFactor, occlusion);
    #endif

	//Sky
    vec3 skyColor = atmosphereColor * (1.0 + Bayer8(gl_FragCoord.xy) / 64.0);

	#ifndef NETHER
    float nebulaFactor = 0.0;

    #ifdef ROUND_SUN_MOON
    drawSunMoon(skyColor, worldPos.xyz, nViewPos, VoU, VoS, VoM, caveFactor, occlusion);
    #endif

	#if MC_VERSION >= 12104 && defined OVERWORLD
    VoU *= 1.0 - isPaleGarden;
	#endif

    #ifdef AURORA
    drawAurora(skyColor, worldPos.xyz, caveFactor, occlusion);
    #endif

    if (atmosphereHardMixFactor < 1.0) {
        #ifdef MILKY_WAY
        drawMilkyWay(skyColor, worldPos.xyz, VoU, caveFactor, nebulaFactor);
        #endif

        #ifdef STARS
        drawStars(skyColor, worldPos.xyz, VoU, VoS, caveFactor, nebulaFactor, occlusion, 0.7);

        #ifdef SHOOTING_STARS
        getShootingStars(skyColor, worldPos.xyz, VoU, VoS);
        #endif

        #ifdef RAINBOW
        getRainbow(skyColor, worldPos.xyz, VoU, 1.75, 0.05, caveFactor);
        #endif
    }

    #endif

    #ifdef END_NEBULA
    drawEndNebula(skyColor, worldPos.xyz, VoU, VoS);
    #endif

    #ifdef END_STARS
    drawStars(skyColor, worldPos.xyz, VoU, VoS, 1.0, nebulaFactor, occlusion, 0.85);
    #endif

    //Planar Clouds
    #ifdef PLANAR_CLOUDS
    skyColor = fmix(skyColor, pc.rgb, pc.a * pc.a);
    #endif
	#endif

    skyColor *= 1.0 - blindFactor;
    #if MC_VERSION >= 11900
    skyColor *= 1.0 - darknessFactor;
    #endif

    #if defined DISTANT_HORIZONS
    if (dhZ0 == 1.0 && z0 == 1.0) color = skyColor;
    #elif defined VOXY
    if (vxZ0 == 1.0 && z0 == 1.0) color = skyColor;
    #else
    if (z0 == 1.0) color = skyColor;
    #endif

	//Apply fog before the clouds in Overworld
    #ifdef SS_SHADOWS
    float shadowMask = texture2D(colortex3, texCoord).b;
    float shadowVisibility = maxOf(abs(worldPos.xyz) / (vec3(min(shadowDistance, far))));
            shadowVisibility = clamp(shadowVisibility, 0.0, 1.0);
            shadowVisibility = 1.0 - pow6(shadowVisibility);

            #ifdef OVERWORLD
            shadowVisibility *= caveFactor;
            #endif
    #endif
    
	#if defined DISTANT_HORIZONS
	if (z0 != 1.0) {
        #ifdef SS_SHADOWS
        if (shadowVisibility < 1.0 && shadowMask > 0.0) {
            vec3 screenSpaceShadow = computeScreenSpaceShadows(viewPos.xyz, lightVec, depthtex0, gbufferProjection, gbufferProjectionInverse, blueNoiseDither, shadowMask);
            color.rgb *= mix(screenSpaceShadow, vec3(1.0), shadowVisibility);
        }
        #endif

        #ifdef SSAO
        color.rgb *= getAmbientOcclusion(z0, depthtex0, gbufferProjectionInverse);
        #endif

		Fog(color, viewPos.xyz, atmosphereColor, z0);
	} else if (dhZ0 != 1.0) {
		vec4 dhScreenPos = vec4(texCoord, dhZ0, 1.0);
		vec4 dhViewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
			 dhViewPos /= dhViewPos.w;

        #ifdef SS_SHADOWS
        if (shadowMask > 0.0) {
            color *= computeScreenSpaceShadows(dhViewPos.xyz, lightVec, dhDepthTex0, dhProjection, dhProjectionInverse, blueNoiseDither, shadowMask);
        }
        #endif

        #ifdef SSAO
        color.rgb *= getAmbientOcclusion(dhZ0, dhDepthTex0, dhProjectionInverse);
        #endif

        Fog(color, dhViewPos.xyz, atmosphereColor, z0);
	}
	#elif defined VOXY
    if (z0 < 1.0) {
        #ifdef SS_SHADOWS
        if (shadowVisibility < 1.0 && shadowMask > 0.0) {
            vec3 screenSpaceShadow = computeScreenSpaceShadows(viewPos.xyz, lightVec, depthtex0, gbufferProjection, gbufferProjectionInverse, blueNoiseDither, shadowMask);
            color.rgb *= mix(screenSpaceShadow, vec3(1.0), shadowVisibility);
        }
        #endif

        #ifdef SSAO
        color.rgb *= getAmbientOcclusion(z0, depthtex0, gbufferProjectionInverse);
        #endif

        Fog(color, viewPos.xyz, atmosphereColor, z0);
    #if !defined END
    } else if (vxZ0 < 1.0) {
    #else
    } else if (vxZ0 <= 1.0) {
    #endif
        vec4 vxScreenPos = vec4(texCoord, vxZ0, 1.0);
        vec4 vxViewPos = vxProjInv * (vxScreenPos * 2.0 - 1.0);
                vxViewPos /= vxViewPos.w;

        if (vxZ0 < 1.0) {
            #ifdef SS_SHADOWS
            if (shadowMask > 0.0) {
                color.rgb *= computeScreenSpaceShadows(vxViewPos.xyz, lightVec, vxDepthTexOpaque, vxProj, vxProjInv, blueNoiseDither, shadowMask);
            }
		    #endif

            #ifdef SSAO
            color.rgb *= getAmbientOcclusion(vxZ0, vxDepthTexOpaque, vxProjInv);
            #endif
        }

        Fog(color, vxViewPos.xyz, atmosphereColor, vxZ0);
    }
    #else
    if (z0 < 1.0) {
        #ifdef SSAO
        color.rgb *= getAmbientOcclusion(z0, depthtex0, gbufferProjectionInverse);
        #endif

        Fog(color, viewPos.xyz, atmosphereColor, z0);
    }
    #endif

	//Volumetric Clouds
	#if defined VOLUMETRIC_CLOUDS || defined END_DISK
	vc.rgb = pow(vc.rgb, vec3(1.0 / 2.2));
    vc.rgb = mix(vc.rgb, atmosphereColor, 0.4);

	#ifdef DISTANT_HORIZONS
	cloudDepth /= (2.0 * dhFarPlane);
	#else
	float farPlane = far + vxRenderDistance * 16.0;
	cloudDepth /= (2.0 * farPlane);
	#endif

	color = fmix(color, vc.rgb, vc.a);
	#endif

    /* DRAWBUFFERS:045 */
    gl_FragData[0].rgb = color;
	gl_FragData[1].rgb = pow(color.rgb, vec3(0.125)) * 0.5;
	gl_FragData[2].r = cloudDepth;
}

#endif


//**//**//**//**//**//**//**//**//**//**//**//**//**//**//


#ifdef VSH

// VSH Data //
out vec2 texCoord;

// Main //
void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}

#endif