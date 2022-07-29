float getBlueNoise(vec2 coord) {
    return texture2D(noisetex, texCoord * vec2(viewWidth, viewHeight) / 256.0).g;
}

