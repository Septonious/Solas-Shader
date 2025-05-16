//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;
in vec3 sunVec;

//Uniforms//
uniform int frameCounter;

uniform float viewWidth, viewHeight;

#ifdef DH_SCREENSPACE_SHADOWS
uniform float timeAngle;
uniform float near, far;
uniform float dhNearPlane, dhFarPlane;

uniform vec3 sunPosition;

uniform sampler2D dhDepthTex1;
#endif

uniform sampler2D noisetex, depthtex1;
uniform sampler2D colortex0;

#ifdef GI
uniform sampler2D colortex3;
uniform sampler2D shadowcolor0, shadowcolor1;
uniform sampler2D shadowtex1;

uniform mat4 shadowModelView, shadowProjection;
#endif

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;

#ifdef DH_SCREENSPACE_SHADOWS
uniform mat4 dhProjection, dhProjectionInverse;
#endif

//Includes//
#include "/lib/util/ToScreen.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"

#ifdef GI
#include "/lib/util/encode.glsl"
#include "/lib/lighting/rsm.glsl"
#endif

#ifdef DH_SCREENSPACE_SHADOWS
#include "/lib/util/ToViewDH.glsl"
#include "/lib/lighting/screenSpaceDHShadows.glsl"
#endif

//Program//
void main() {
	vec4 color = texture2D(colortex0, texCoord);
	vec3 gi = vec3(0.0);
	float shadow = 0.0;

    float z1 = texture2D(depthtex1, texCoord).r;

    vec3 screenPos = vec3(texCoord, z1);
    vec3 viewPos = ToView(screenPos);
    vec3 worldPos = ToWorld(viewPos);

	#ifdef DH_SCREENSPACE_SHADOWS
	float dhZ1 = texture2D(dhDepthTex1, texCoord).r;

	shadow = screenSpaceDHShadows(z1, dhZ1);
	#endif

	#ifdef GI
    vec3 gbuffersData = texture2D(colortex3, texCoord).rgb;
    vec3 normal = normalize(decodeNormal(gbuffersData.rg));
    vec3 worldNormal = normalize(ToWorld(normal * 100000.0));

	gi = computeRSM(worldNormal, worldPos, viewPos, z1) * GI_BRIGHTNESS;
	#endif

	/* DRAWBUFFERS:045 */
	gl_FragData[0] = color;
	gl_FragData[1].rgb = gi;
	gl_FragData[2].r = shadow;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;
out vec3 sunVec;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	//Sun Vector
	getSunVector(gbufferModelView, timeAngle, sunVec);

	//Position
	gl_Position = ftransform();
}

#endif