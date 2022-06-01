//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
varying vec2 texCoord;

//Uniforms//
uniform sampler2D colortex0;

//Includes//

void main() {
	vec4 albedo = texture2D(colortex0, texCoord);

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
varying vec2 texCooord;

//Uniforms//

//Includes//

void main() {
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();
}


#endif