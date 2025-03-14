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

#ifdef DISTANT_HORIZONS
uniform sampler2D dhDepthTex0;

uniform mat4 dhProjectionInverse;
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

	#ifndef DISTANT_HORIZONS
	if (z0 < 1.0 && z0 > 0.56) {
		color *= getAmbientOcclusion(z0);
	}
	#else
	float dhZ = texture2D(dhDepthTex0, texCoord).r;

	if (z0 < 1.0) {
		color *= getAmbientOcclusion(z0);
	} else if (dhZ < 1.0) {
		z = 1.0 - 1e-5;
		
		vec4 dhScreenPos = vec4(texCoord, dhZ, 1.0);
		viewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
		viewPos /= viewPos.w;

		#ifdef AO
		color.rgb *= getAmbientOcclusionDH(dhZ);
		#endif
	}
	#endif
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