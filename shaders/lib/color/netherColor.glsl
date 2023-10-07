uniform vec3 fogColor;

vec3 netherColSqrt = pow(normalize(fogColor + 0.00000001), vec3(0.75));