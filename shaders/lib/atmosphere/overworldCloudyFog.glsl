float getOverworldFogSample(vec3 fogPos, vec2 wind) {
    fogPos *= 0.25;

    float n3da = texture2D(noisetex, fogPos.xz * 0.001 + floor(fogPos.y * 0.15) * 0.15).r;
    float n3db = texture2D(noisetex, fogPos.xz * 0.001 + floor(fogPos.y * 0.15 + 1.0) * 0.15).r;

    float cloudyNoise = mix(n3da, n3db, fract(fogPos.y * 0.15));
          cloudyNoise = max(cloudyNoise - 0.4, 0.0);
          cloudyNoise = min(cloudyNoise * 8.0, 1.0);
          cloudyNoise *= 1.0 + cloudyNoise * cloudyNoise;
    return cloudyNoise;
}