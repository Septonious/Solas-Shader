#include "/lib/util/reprojection.glsl"

vec4 ToView(vec2 coord, float z0){
	vec4 screenPos = vec4(coord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	return viewPos /= viewPos.w;
}

vec3 ToWorld(vec3 pos) {
	return mat3(gbufferModelViewInverse) * pos + gbufferModelViewInverse[3].xyz;
}

vec4 getTemporalAccumulation(inout vec3 color, float tempData, sampler2D temptex) {
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	vec3 coord = vec3(texCoord, z1);
	vec2 prvCoord = Reprojection(coord);

	vec3 tempColor = texture2D(temptex, prvCoord).gba;
	vec3 viewPos = ToView(texCoord, z0).xyz;
	vec3 previousPos = ToWorld(ToView(prvCoord, z0).xyz);
    vec3 delta = ToWorld(viewPos.xyz) - previousPos;
	
    float posWeight = max(exp(-dot(delta, delta) * 3.0), 0.0);
	float totalWeight = float(clamp(prvCoord, vec2(0.0), vec2(1.0)) == prvCoord);
    	  totalWeight *= 0.75 * posWeight * (1.0 - float(z0 < 0.56));
	
	color = clamp(mix(color, tempColor, totalWeight), vec3(0.0), vec3(65e3));

	return vec4(tempData, color);
}