if (mat == 107) {
    #ifdef EMISSIVE_ENDER_DRAGON
    vec2 pos = (worldPos.xz + cameraPosition.xz) * 0.5 + (worldPos.xy + cameraPosition.xy) * 0.5 + (worldPos.zy + cameraPosition.zy) * 0.5;
    pos.x *= 0.5;
    float noise = max(texture2D(noisetex, pos * 0.25).r - 0.55, 0.0) * float(lAlbedo < 0.07);
    albedo.rgb += vec3(1.0, 0.15, 0.85) * noise * noise * 32;
    #endif
}