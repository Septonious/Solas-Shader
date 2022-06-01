vec3 blocklightColSqrt = vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B) * BLOCKLIGHT_I / 255.0;
vec3 blocklightCol = blocklightColSqrt * blocklightColSqrt;