#ifdef NETHER
uniform vec3 fogColor;

vec3 netherCol = sqrt(normalize(fogColor + 0.00000001));
vec3 netherColSqrt = sqrt(netherCol);
#endif