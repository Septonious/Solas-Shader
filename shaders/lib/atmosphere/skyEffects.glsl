float getSpiralWarping(vec2 coord){
	float whirl = END_VORTEX_WHIRL;
	float arms = END_VORTEX_ARMS;

    coord = vec2(atan(coord.y, coord.x) + frameTimeCounter * 0.05, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow8(1.0 - coord.y) * 24.0;
    float spiral = sin((coord.x + sqrt(coord.y) * whirl) * arms) + center - coord.y;

    return clamp(spiral * 0.1, 0.0, 1.0);
}

#if defined STARS || defined END_STARS
#include "/lib/atmosphere/stars.glsl"
#endif

#ifdef MILKY_WAY
#include "/lib/atmosphere/milkyWay.glsl"
#endif

#ifdef END_NEBULA
#include "/lib/atmosphere/endNebula.glsl"
#endif

#ifdef END_VORTEX
#include "/lib/atmosphere/endVortex.glsl"
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