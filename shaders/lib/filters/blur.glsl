vec2 pixelSize = 1.0 / vec2(viewWidth, viewHeight);

const vec2 blurOffsets4[4] = vec2[4](
   vec2(0.21848650099008202, -0.09211370200809937),
   vec2(-0.5866112654782878, 0.32153793477769893),
   vec2(-0.06595078555407359, -0.879656059066481),
   vec2(0.43407555004227927, 0.6502318262968816)
);

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

const vec2 blurOffsets16[16] = vec2[16](
   vec2(0.18993645671348536, 0.02708711407659152),
   vec2(-0.21261242652069953, 0.2339129324694907),
   vec2(0.04771781344140756, -0.3666840644525993),
   vec2(0.297730981239584, 0.398259878229082),
   vec2(-0.509063425827436, -0.06528681462854097),
   vec2(0.507855152944665, -0.2875976005206389),
   vec2(-0.15230616564632418, 0.6426121151781916),
   vec2(-0.30240170651828074, -0.5805072900736001),
   vec2(0.6978019230005561, 0.2771173334141519),
   vec2(-0.6990963248129052, 0.3210960724922725),
   vec2(0.3565142601623699, -0.7066415061851589),
   vec2(0.266890002328106, 0.8360191043249159),
   vec2(-0.7515861305520581, -0.4160987619581504),
   vec2(0.9102937449894895, -0.17014527555321657),
   vec2(-0.5343471434373126, 0.8058593459499529),
   vec2(-0.1133270115046468, -0.9490025827627441)
);

vec4 getDiskBlur4(sampler2D colortex, vec2 coord, float strength) {
	vec4 blur = vec4(0.0);

	for(int i = 0; i < 4; i++) {
		vec2 pixelOffset = blurOffsets4[i] * pixelSize * strength;
		blur += texture2D(colortex, coord + pixelOffset);
	}

	blur *= 0.25;

	return blur;
}

vec4 getDiskBlur8(sampler2D colortex, vec2 coord, float strength) {
	vec4 blur = vec4(0.0);

	for(int i = 0; i < 8; i++) {
		vec2 pixelOffset = blurOffsets8[i] * pixelSize * strength;
		blur += texture2D(colortex, coord + pixelOffset);
	}

	blur *= 0.125;

	return blur;
}

vec4 getDiskBlur16(sampler2D colortex, vec2 coord, float strength) {
	vec4 blur = vec4(0.0);

	for(int i = 0; i < 16; i++) {
		vec2 pixelOffset = blurOffsets16[i] * pixelSize * strength;
		blur += texture2D(colortex, coord + pixelOffset);
	}

	blur *= 0.0625;

	return blur;
}