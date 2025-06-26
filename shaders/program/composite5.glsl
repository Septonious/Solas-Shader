//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
#if defined LPV_FOG || defined VL || defined FIREFLIES
uniform float viewHeight, viewWidth;

uniform sampler2D colortex1;
#endif

uniform sampler2D colortex0;

const vec2 vlOffsets[4] = vec2[4](
	vec2( 1.5,  0.5),
	vec2(-0.5,  1.5),
	vec2(-1.5, -0.5),
	vec2( 0.5, -1.5)
);

#ifdef FIREFLIES
const vec2 blurOffsets8[8] = vec2[8](
   vec2(0.2921473492144121, 0.03798942536906266),
   vec2(-0.27714274097351554, 0.3304853027892154),
   vec2(0.09101981507673855, -0.5188871157785563),
   vec2(0.44459182774878003, 0.5629069824170247),
   vec2(-0.6963877647721594, -0.09264703741542105),
   vec2(0.7417522811565185, -0.4070419658858473),
   vec2(-0.191856808948964, 0.9084732299066597),
   vec2(-0.40412395850181015, -0.8212788214021378)
);

float getDiskBlur8(sampler2D colortex, vec2 coord, float strength) {
	float blur = 0.0;

	for (int i = 0; i < 8; i++) {
		vec2 pixelOffset = blurOffsets8[i] * (1.0 / vec2(viewWidth, viewHeight)) * strength;
		blur += texture2D(colortex, coord + pixelOffset).a;
	}
	blur *= 0.125;

	return blur;
}
#endif

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#if defined LPV_FOG || defined VL
	vec3 volumetrics = texture2D(colortex1, texCoord + vlOffsets[0] / vec2(viewWidth, viewHeight)).rgb;
		 volumetrics+= texture2D(colortex1, texCoord + vlOffsets[1] / vec2(viewWidth, viewHeight)).rgb;
		 volumetrics+= texture2D(colortex1, texCoord + vlOffsets[2] / vec2(viewWidth, viewHeight)).rgb;
		 volumetrics+= texture2D(colortex1, texCoord + vlOffsets[3] / vec2(viewWidth, viewHeight)).rgb;
	volumetrics *= 0.25;
	volumetrics = pow8(volumetrics) * 256.0;

	color += volumetrics;

	#ifdef FIREFLIES
	color += getDiskBlur8(colortex1, texCoord, 4.0) * vec3(1.0, 2.0, 0.8) * FIREFLIES_BRIGHTNESS;
	#endif
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = pow(color.rgb, vec3(2.2));
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

//Program//
void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}

#endif