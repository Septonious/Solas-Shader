else if (mat == 109) {
    lightmap.x *= 1.0 - lightmap.x * 0.5;
} else if (mat == 110) {
    albedo.a *= albedo.a;
    albedo.rgb *= 2.0 + 2.0 * pow4(min(length(albedo.rgb), 1.0));
}