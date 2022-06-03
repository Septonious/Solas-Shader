uniform vec3 fogColor;
vec3 netherColSqrt = normalize(fogColor);
vec3 netherCol = netherColSqrt * netherColSqrt;