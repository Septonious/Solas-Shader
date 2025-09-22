#if defined STARS || defined END_STARS
#include "/lib/atmosphere/stars.glsl"
#endif

#ifdef MILKY_WAY
#include "/lib/atmosphere/milkyWay.glsl"
#endif

#ifdef END_NEBULA
#include "/lib/atmosphere/endNebula.glsl"
#endif

#ifdef AURORA
#include "/lib/atmosphere/aurora.glsl"
#endif

#ifdef PLANAR_CLOUDS
#include "/lib/atmosphere/planarClouds.glsl"
#endif

#ifdef RAINBOW
#include "/lib/atmosphere/rainbow.glsl"
#endif