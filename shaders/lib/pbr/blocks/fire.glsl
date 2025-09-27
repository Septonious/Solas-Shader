else if (material == 15) {
    vec2 pos = worldPos.zy + cameraPosition.zy + worldPos.xy + cameraPosition.xy;
    pos.y *= 0.25;
    float fireNoise = texture2D(noisetex, (pos + vec2(0.0, -frameTimeCounter * 2.0)) * 0.05).r;

    albedo.rgb *= 0.5;
    albedo.rgb *= pow(vec3(TLCF_R, TLCF_G, TLCF_B), vec3(1.0 - 0.25 * lAlbedo * lAlbedo)) * pow4(fireNoise) * 24.0;
    albedo.rgb = clamp(albedo.rgb, 0.0, 1.0);
    emission = length(albedo.rgb);
} else if (material == 16) {
    vec2 pos = worldPos.zy + cameraPosition.zy + worldPos.xy + cameraPosition.xy;
    pos.y *= 0.25;
    float fireNoise = texture2D(noisetex, (pos + vec2(0.0, -frameTimeCounter * 2.0)) * 0.05).r;

    albedo.rgb *= 0.5;
    albedo.rgb *= pow(vec3(SOUL_R, SOUL_G, SOUL_B), vec3(1.0 - 0.25 * lAlbedo * lAlbedo)) * pow4(fireNoise) * 24.0;
    albedo.rgb = clamp(albedo.rgb, 0.0, 1.0);
    emission = length(albedo.rgb); 
}