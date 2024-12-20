//Settings//
#include "/lib/common.glsl"

#define SHADOW

#ifdef FSH

//Varyings//
in vec2 texCoord;
in vec4 color;

in float overdrawCull;

//Uniforms//
uniform sampler2D tex;

//Program//
void main() {
    vec4 albedo = texture2D(tex, texCoord) * color;

	if (albedo.a < 0.01 || overdrawCull < 1.0) {
		discard;
		return;
	}
	
	gl_FragData[0] = albedo;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;
out vec4 color;

out float overdrawCull;

//Uniforms//
uniform float far;

uniform mat4 shadowProjection, shadowProjectionInverse;
uniform mat4 shadowModelView, shadowModelViewInverse;

//Program//
void main() {
	//Coord
	texCoord = gl_MultiTexCoord0.xy;

	//Color & Position
	color = gl_Color;

	vec3 position = mat3(gl_ModelViewMatrix) * vec3(gl_Vertex) + gl_ModelViewMatrix[3].xyz;
	vec3 worldPos = mat3(shadowModelViewInverse) * position + shadowModelViewInverse[3].xyz;
	overdrawCull = 1.0 - clamp(1.0 - length(worldPos) / max(far + 8.0, 0.0), 0.0, 1.0);

	gl_Position = vec4(projMAD(gl_ProjectionMatrix, position), 1.0);

	float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	float distortFactor = dist * shadowMapBias + (1.0 - shadowMapBias);
	
	gl_Position.xy *= 1.0 / distortFactor;
	gl_Position.z = gl_Position.z * 0.2;
}

#endif