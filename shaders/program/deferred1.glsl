//Settings//
#include "/lib/common.glsl"

#define DEFERRED_2

#ifdef FSH

//Varyings//
in vec2 texCoord;

#if defined OVERWORLD || defined END
in vec3 sunVec, upVec;
#endif

//Uniforms//
uniform int isEyeInWater;

#if defined OVERWORLD || defined END
uniform float timeBrightness, timeAngle, frameTimeCounter;
#endif

uniform float far, rainStrength;
uniform float blindFactor;
uniform float viewWidth, viewHeight;

#ifdef RAINBOW
uniform float wetness;
#endif

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform sampler2D colortex0, colortex2;
uniform sampler2D depthtex0;

#ifdef INTEGRATED_SPECULAR
uniform sampler2D colortex5, colortex6;
#endif

#ifdef NEBULA
uniform sampler2D noisetex;
#endif

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

#ifdef INTEGRATED_SPECULAR
uniform mat4 gbufferProjection;
#endif

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;

#if defined OVERWORLD || defined END
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
#endif

vec2 glowOffsets[16] = vec2[16](
    vec2( 0.0, -1.0),
    vec2(-1.0,  0.0),
    vec2( 1.0,  0.0),
    vec2( 0.0,  1.0),
    vec2(-1.0, -2.0),
    vec2( 0.0, -2.0),
    vec2( 1.0, -2.0),
    vec2(-2.0, -1.0),
    vec2( 2.0, -1.0),
    vec2(-2.0,  0.0),
    vec2( 2.0,  0.0),
    vec2(-2.0,  1.0),
    vec2( 2.0,  1.0),
    vec2(-1.0,  2.0),
    vec2( 0.0,  2.0),
    vec2( 1.0,  2.0)
);

void GlowOutline(inout vec3 color){
	for(int i = 0; i < 16; i++){
		vec2 glowOffset = glowOffsets[i] / vec2(viewWidth, viewHeight);
		float glowSample = texture2D(colortex2, texCoord.xy + glowOffset).b;
		if(glowSample < 0.5){
			if(i < 4) color = vec3(0.0);
			else color = vec3(0.5);
			break;
		}
	}
}

//Includes//
#include "/lib/color/dimensionColor.glsl"

#ifdef OVERWORLD
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/sunMoon.glsl"
#include "/lib/atmosphere/skyEffects.glsl"
#endif

#include "/lib/atmosphere/fog.glsl"

#ifdef INTEGRATED_SPECULAR
#include "/lib/pbr/reflection.glsl"
#include "/lib/util/encode.glsl"
#endif

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	float z0 = texture2D(depthtex0, texCoord).r;
	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec3 skyColor = vec3(0.0);

	#ifdef OVERWORLD
	vec3 worldPos = normalize(mat3(gbufferModelViewInverse) * viewPos.xyz);

	skyColor = getAtmosphere(viewPos.xyz);
	#endif

	if (z0 == 1.0){ //Sky rendering
		#ifdef OVERWORLD
		vec3 nViewPos = normalize(viewPos.xyz);
		float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
		float VoM = clamp(dot(nViewPos, -sunVec), 0.0, 1.0);
		float VoU = dot(nViewPos, upVec);

		if (VoU > 0.0) {
			float nebulaFactor = 0.0;

			#ifdef NEBULA
			getNebula(skyColor, worldPos, viewPos.xyz, VoU, nebulaFactor);
			#endif

			#ifdef STARS
			getStars(skyColor, worldPos, nebulaFactor);
			#endif

			#ifdef RAINBOW
			getRainbow(skyColor, worldPos, viewPos.xyz, VoU, 1.75, 0.05);
			#endif

			#ifdef AURORA
			getAurora(skyColor, viewPos.xyz, worldPos);
			#endif
		}

		getSunMoon(skyColor, VoS, VoM, VoU, lightSun, lightNight);

		#if MC_VERSION >= 11900
		skyColor *= 1.0 - darknessFactor;
		#endif

		color = skyColor * (1.0 - blindFactor);
		color = mix(minLightCol * 0.25, color, ug);
		#endif

		#ifdef NETHER
		color = netherCol.rgb * 0.15;
		#endif

		#ifdef END
		color = endCol.rgb * 0.1;
		#endif
	}

	#ifdef INTEGRATED_SPECULAR
	vec3 terrainData = texture2D(colortex6, texCoord).rgb;
	vec3 normal = DecodeNormal(terrainData.rg);
	float specular = terrainData.b;

	if (specular > 0.0 && z0 > 0.56) {
		float fresnel = clamp(pow2(1.0 + dot(normal, normalize(viewPos.xyz))), 0.0, 1.0);

		vec3 reflection = getReflection(viewPos.xyz, normal, eBS);
		color.rgb = mix(color.rgb, reflection.rgb, fresnel * specular);
	}
	#endif

	if (z0 < 1.0) Fog(color, viewPos.xyz, skyColor);
	float isGlowing = texture2D(colortex2, texCoord).b;
	if (isGlowing > 0.5) GlowOutline(color);

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

#if defined OVERWORLD || defined END
out vec3 sunVec, upVec;
#endif

//Uniforms
#if defined OVERWORLD || defined END
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	#if defined OVERWORLD || defined END
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	
	upVec = normalize(gbufferModelView[1].xyz);
	#endif

	gl_Position = ftransform();
}

#endif