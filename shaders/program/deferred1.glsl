//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#ifdef AO
uniform float far, near;
uniform float viewWidth, viewHeight;
#endif

uniform sampler2D colortex0;

#ifdef AO
uniform sampler2D colortex1, depthtex0;
#endif

//Optifine Constants//
#ifdef AO
const bool colortex1MipmapEnabled = true;
#endif

//Includes//
#ifdef AO
#include "/lib/lighting/getAmbientOcclusion.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef AO
	float z0 = texture2D(depthtex0, texCoord).r;

	if (z0 != 1.0) color *= getAmbientOcclusion(z0);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;
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