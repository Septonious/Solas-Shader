float getBlueNoise(vec2 coord) {
    return texelFetch(noisetex, ivec2(coord) % 256, 0).r;
}

