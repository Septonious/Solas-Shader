//Settings//
#include "/lib/common.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
in float mat;
in vec2 texCoord;
in vec4 color;

#ifdef WATER_CAUSTICS
in vec4 position;
#endif

//Uniforms//
uniform sampler2D tex;

#ifdef WATER_CAUSTICS
uniform float frameTimeCounter;

uniform vec3 cameraPosition;

uniform sampler2D noisetex;

//Includes//
#include "/lib/color/waterColor.glsl"
#include "/lib/water/waterCaustics.glsl"
#endif

//Program//
void main() {
    vec4 albedo = texture2D(tex, texCoord.xy) * color;

    #ifdef SHADOW_COLOR
	albedo.rgb *= (1.0 - pow2(pow8(pow8(albedo.a)))) * 4.0;
	albedo.rgb = pow16(albedo.rgb);

	#ifdef WATER_CAUSTICS
	float water = float(mat > 0.98 && mat < 1.02);

	if (water > 0.9){
		float caustics = getCaustics(position.xyz + cameraPosition.xyz);
		albedo.rgb = waterColor.rgb * caustics;
	}
	#endif
	#endif
	
	gl_FragData[0] = albedo;
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
out float mat;
out vec2 texCoord;
out vec4 color;
out vec4 position;

//Uniforms//
uniform mat4 shadowProjection, shadowProjectionInverse;
uniform mat4 shadowModelView, shadowModelViewInverse;

//Attributes//
attribute vec4 mc_Entity;

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.xy;

	color = gl_Color;
	
	mat = 0.0;
	if (mc_Entity.x == 1) mat = 1.0;
	
	position = shadowModelViewInverse * shadowProjectionInverse * ftransform();
	
	gl_Position = shadowProjection * shadowModelView * position;

	float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	float distortFactor = dist * shadowMapBias + (1.0 - shadowMapBias);
	
	gl_Position.xy *= 1.0 / distortFactor;
	gl_Position.z = gl_Position.z * 0.2;
}

#endif