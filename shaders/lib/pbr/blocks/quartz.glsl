if (material2 == 309) {//Quartz & Calcite
    smoothness = clamp(pow3(length(albedo.rgb * albedo.rgb * albedo.rgb * albedo.rgb * albedo.rgb)) * 0.4, 0.0, 0.5);
}