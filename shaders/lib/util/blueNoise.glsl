float getBlueNoise(vec2 coord) {
    return texelFetch(depthtex2, ivec2(coord) % 1024, 0).r;
}