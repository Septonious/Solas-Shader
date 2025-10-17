else if (material == 14) {
    emission = pow6(lAlbedo) * 0.4;
    vec2 pos = (worldPos.xz + cameraPosition.xz) * 0.5 + (worldPos.xy + cameraPosition.xy) * 0.5 + (worldPos.zy + cameraPosition.zy) * 0.5;
         pos.x *= 0.5;
    float amethystNoise = texture2D(noisetex, (pos + vec2(-frameTimeCounter * 0.1, frameTimeCounter * 0.03)) * 0.2).r;
    albedo.rgb = mix(albedo.rgb, normalize(vec3(AM_R, AM_G, AM_B)), 6.0 * pow4(amethystNoise));
}