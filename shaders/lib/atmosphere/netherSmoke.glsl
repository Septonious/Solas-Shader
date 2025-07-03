float getNetherFogSample(vec3 fogPos) {
    fogPos.x *= 0.5 + cos(fogPos.y * 0.5 + frameTimeCounter * 0.5) * 0.0006;
    fogPos.z *= 0.5 + sin(fogPos.y * 0.3 + frameTimeCounter * 0.4) * 0.0008;

    float n3da = texture2D(noisetex, fogPos.xz * 0.005 + floor(fogPos.y * 0.1) * 0.1).r;
    float n3db = texture2D(noisetex, fogPos.xz * 0.005 + floor(fogPos.y * 0.1 + 1.0) * 0.1).r;

    float cloudyNoise = mix(n3da, n3db, fract(fogPos.y * 0.1));
          cloudyNoise = max(cloudyNoise - 0.5, 0.0);
          cloudyNoise *= 1.0 + pow3(cloudyNoise) * 64.0;
    return cloudyNoise;
}