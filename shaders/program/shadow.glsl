//Settings//
#include "/lib/common.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
#ifdef WATER_CAUSTICS
flat in int mat;
#endif

in vec2 texCoord;

#ifdef WATER_CAUSTICS
in vec3 worldPos;
#endif

in vec4 color;

//Uniforms//
#ifdef WATER_CAUSTICS
uniform int isEyeInWater;

uniform float frameTimeCounter;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 fogColor;
uniform vec3 cameraPosition;

uniform sampler2D shadowcolor1;
#endif

uniform sampler2D tex;

//Common Variables//
#ifdef WATER_CAUSTICS
float eBS = eyeBrightnessSmooth.y / 240.0;
#endif

//Includes//
#ifdef WATER_CAUSTICS
#include "/lib/water/waterCaustics.glsl"
#endif

//Program//
void main() {
    vec4 albedo = texture2D(tex, texCoord) * color;

    #ifdef SHADOW_COLOR
	albedo.rgb *= 1.0 - pow8(pow32(albedo.a));

	#ifdef WATER_CAUSTICS
	if (mat == 1){
		float caustics = getWaterCaustics(worldPos + cameraPosition);
		if (isEyeInWater == 0) {
			albedo.rgb = vec3(0.25 + mix(waterColor, vec3(1.0), 0.5) * caustics * WATER_CAUSTICS_STRENGTH);
		} else {
			albedo.rgb = vec3(mix(waterColor, vec3(1.0), 0.5) * caustics * WATER_CAUSTICS_STRENGTH);
		}
	}
	#endif
	#endif
	
	gl_FragData[0] = albedo;
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
#ifdef WATER_CAUSTICS
flat out int mat;
#endif

out vec2 texCoord;

#ifdef WATER_CAUSTICS
out vec3 worldPos;
#endif

out vec4 color;

//Uniforms//
#ifdef WAVING_BLOCKS
uniform float frameTimeCounter;

uniform vec3 cameraPosition;
#endif

uniform mat4 shadowProjection, shadowProjectionInverse;
uniform mat4 shadowModelView, shadowModelViewInverse;

//Attributes//
attribute vec4 mc_Entity;

#ifdef WAVING_BLOCKS
attribute vec4 mc_midTexCoord;
#endif

//Includes//
#ifdef WAVING_BLOCKS
#include "/lib/util/waving.glsl"
#endif

//Program//
void main() {
	//Coord
	texCoord = gl_MultiTexCoord0.xy;

	#ifdef WAVING_BLOCKS
	vec2 lightMapCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lightMapCoord = clamp(lightMapCoord, vec2(0.0), vec2(0.9333, 1.0));
	#endif

	//Materials
	#ifdef WATER_CAUSTICS
	mat = int(mc_Entity.x);
	#endif
	
	//Color & Position
	color = gl_Color;

	vec4 position = shadowModelViewInverse * shadowProjectionInverse * ftransform();

	#ifdef WAVING_BLOCKS
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	position.xyz = getWavingBlocks(position.xyz, istopv, lightMapCoord.y);
	#endif

	#ifdef WATER_CAUSTICS
	worldPos = position.xyz;
	#endif

	gl_Position = shadowProjection * shadowModelView * position;

	float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	float distortFactor = dist * shadowMapBias + (1.0 - shadowMapBias);
	
	gl_Position.xy *= 1.0 / distortFactor;
	gl_Position.z = gl_Position.z * 0.2;
}

#endif