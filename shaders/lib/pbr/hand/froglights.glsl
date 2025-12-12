else if ((heldItemId2 >= 32 && heldItemId2 <= 34) || (heldItemId2 >= 32 && heldItemId2 <= 34)) {
    emission = lAlbedo * 0.5;
    albedo.rgb = pow(albedo.rgb, vec3(1.75)) * 0.75;
}