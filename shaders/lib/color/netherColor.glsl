uniform vec3 fogColor;
vec4 netherColSqrt = vec4(normalize(fogColor), length(fogColor));

vec4 netherCol = netherColSqrt * netherColSqrt;