void generateIPBR(inout vec4 albedo, in vec3 worldPos, in vec3 viewPos, inout vec2 lightmap, inout float emission, inout float smoothness2, inout float metalness, inout float subsurface) {
    int material = max(mat - 10000, 0);
    int material2 = max(mat - 20000, 0);
    float lAlbedo = clamp(length(albedo.rgb), 0.0, 1.0);
    float smoothness = 0.0;

    #include "/lib/pbr/blocks/amethyst_block.glsl"
    #include "/lib/pbr/blocks/amethyst.glsl"
    #include "/lib/pbr/blocks/beacon.glsl"
    #include "/lib/pbr/blocks/black_materials.glsl"
    #include "/lib/pbr/blocks/brewing_stand.glsl"
    #include "/lib/pbr/blocks/bricks.glsl"
    #include "/lib/pbr/blocks/calcite.glsl"
    #include "/lib/pbr/blocks/candles_corals.glsl"
    #include "/lib/pbr/blocks/cave_berries.glsl"
    #include "/lib/pbr/blocks/concrete.glsl"
    #include "/lib/pbr/blocks/creaking_heart.glsl"
    #include "/lib/pbr/blocks/dark_materials.glsl"
    #include "/lib/pbr/blocks/enchanting_table.glsl"
    #include "/lib/pbr/blocks/end_portal_frame.glsl"
    #include "/lib/pbr/blocks/end_stone.glsl"
    #include "/lib/pbr/blocks/froglights.glsl"
    #include "/lib/pbr/blocks/full_emitters.glsl"
    #include "/lib/pbr/blocks/glow_lichen_sea_pickle.glsl"
    #include "/lib/pbr/blocks/jack_o_lantern.glsl"
    #include "/lib/pbr/blocks/magma_block.glsl"
    #include "/lib/pbr/blocks/nether_logs.glsl"
    #include "/lib/pbr/blocks/nether_plants.glsl"
    #include "/lib/pbr/blocks/planks.glsl"
    #include "/lib/pbr/blocks/polished_materials.glsl"
    #include "/lib/pbr/blocks/powered_rail.glsl"
    #include "/lib/pbr/blocks/prismarine.glsl"
    #include "/lib/pbr/blocks/purpur.glsl"
    #include "/lib/pbr/blocks/quartz.glsl"
    #include "/lib/pbr/blocks/redstone_lamp.glsl"
    #include "/lib/pbr/blocks/redstone_ore.glsl"
    #include "/lib/pbr/blocks/reflective_materials.glsl"
    #include "/lib/pbr/blocks/sand.glsl"
    #include "/lib/pbr/blocks/sculk.glsl"
    #include "/lib/pbr/blocks/soul_emitters.glsl"
    #include "/lib/pbr/blocks/spawner.glsl"
    #include "/lib/pbr/blocks/terracotta.glsl"
    #include "/lib/pbr/blocks/torch_lantern.glsl"
    #include "/lib/pbr/blocks/water_cauldron.glsl"
    #include "/lib/pbr/blocks/wet_farmland.glsl"

    #ifdef EMISSIVE_FLOWERS
    #include "/lib/pbr/blocks/flowers.glsl"
    #endif

    #ifdef EMISSIVE_ORES
    #include "/lib/pbr/blocks/ores.glsl"
    #endif

    #ifdef GENERATED_EMISSION
    emission = clamp(emission * EMISSION_STRENGTH, 0.0, 8.0);
    #else
    emission = 0.0;
    #endif

    #ifdef GENERATED_SPECULAR
    smoothness2 = clamp(smoothness, 0.0, 0.95);
    metalness = 1.0;
    #endif
}