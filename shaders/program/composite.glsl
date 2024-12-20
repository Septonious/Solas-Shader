//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef GI
uniform int frameCounter;

uniform float viewWidth, viewHeight;

uniform sampler2D colortex3, depthtex0, noisetex;
uniform sampler2D shadowcolor0, shadowcolor1;
uniform sampler2D shadowtex1;

uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView, shadowProjection;
#endif

uniform sampler2D colortex0;

//Includes//
#ifdef GI
#include "/lib/util/encode.glsl"
#include "/lib/util/ToScreen.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/lighting/rsm.glsl"
#endif

//Program//
void main() {
	vec4 color = texture2D(colortex0, texCoord);

	#ifdef GI
    float z0 = texture2D(depthtex0, texCoord).r;

    vec3 screenPos = vec3(texCoord, z0);
    vec3 viewPos = ToView(screenPos);
    vec3 worldPos = ToWorld(viewPos);

    vec3 gbuffersData = texture2D(colortex3, texCoord).rgb;
    vec3 normal = normalize(decodeNormal(gbuffersData.rg));
    vec3 worldNormal = normalize(ToWorld(normal * 100000.0));

	vec3 gi = computeRSM(worldNormal, worldPos, viewPos, z0) * GI_BRIGHTNESS;
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;

	#ifdef GI
	/* DRAWBUFFERS:04 */
	gl_FragData[1].rgb = gi;
	#endif
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}


#endif