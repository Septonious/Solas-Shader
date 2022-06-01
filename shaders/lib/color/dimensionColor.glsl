#ifdef OVERWORLD
#include "lightColor.glsl"
#endif

#ifdef NETHER
#include "netherColor.glsl"
#endif

#ifdef END
#include "endColor.glsl"
#endif

vec3 minLightColSqrt = vec3(MINLIGHT_R, MINLIGHT_G, MINLIGHT_B) * MINLIGHT_I / 255.0;
vec3 minLightCol	 = minLightColSqrt * minLightColSqrt * 0.04;