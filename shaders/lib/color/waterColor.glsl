vec3 waterColorSqrt = vec3(WATER_R, WATER_G, WATER_B) / 255.0 * WATER_I;
vec3 waterColor = waterColorSqrt * waterColorSqrt;

float waterFogRange = 64.0 / WATER_FOG_DENSITY;