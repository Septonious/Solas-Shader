//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_BLOCK

#ifdef FSH

//Varyings//
in vec2 texCoord, lmCoord;
in vec3 sunVec, upVec, eastVec, normal;
in vec4 color;

//Uniforms//
uniform int blockEntityId;

uniform float nightVision;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight, aspectRatio;
uniform float frameTimeCounter;

uniform vec3 cameraPosition;

uniform sampler2D texture, noisetex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

//Common Variables//
float sunVisibility  = clamp((dot( sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);

vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

//Includes//
#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/dimensionColor.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/lighting/forwardLighting.glsl"

//Program//
void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;
	vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	vec3 viewPos = ToNDC(screenPos);
	vec3 worldPos = ToWorld(viewPos);

	if (albedo.a > 0.001){
		GetLighting(albedo.rgb, viewPos, worldPos, lightmap, 0.0, 0.0);
	}

	if (blockEntityId == 20) {
		vec2 portalCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
		portalCoord = (portalCoord - 0.5) * vec2(aspectRatio, 1.0);

		vec3 portColSqrt = vec3(END_R, END_G, END_B) / 255.0 * END_I;
		vec3 portCol = portColSqrt * portColSqrt * 0.05;
		vec2 wind = vec2(0.0, frameTimeCounter * 0.025);

		float portal = texture2D(noisetex, portalCoord * 0.1 + wind * 0.05).r * 0.25 + 0.375;

		#ifdef END
			  portal *= 0.5;
		#endif
			  portal+= texture2D(texture, portalCoord * 0.5 + wind).r * 1.4;
			  portal+= texture2D(texture, portalCoord + wind + 0.15).r;
			  portal+= texture2D(texture, portalCoord * 2.0 + wind + 0.30).r * 0.7;
			  portal+= texture2D(texture, portalCoord * 4.0 + wind + 0.45).r * 0.5;
		
		albedo.rgb = portal * portal * portCol.rgb;
		albedo.a = 1.0;
	}

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = albedo;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord, lmCoord;
out vec3 sunVec, upVec, eastVec, normal;
out vec4 color;

//Uniforms
#if defined OVERWORLD || defined END
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Normal
	normal = normalize(gl_NormalMatrix * gl_Normal);

	//Sun & Other vectors
	#if defined OVERWORLD || defined END
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	
	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);
	#endif

	//Color & Position
	color = gl_Color;

	gl_Position = ftransform();
}

#endif