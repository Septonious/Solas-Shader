#ifdef GBUFFERS_TERRAIN
void generateIPBR(inout vec4 albedo, in vec3 worldPos, in vec3 viewPos, inout vec2 lightmap, in float NoU, inout float emission, inout float smoothness2, inout float metalness, inout float subsurface) {
    int material = max(mat - 10000, 0);
    int material2 = max(mat - 20000, 0);
    float lAlbedo = clamp(length(albedo.rgb), 0.0, 1.0);
    vec3 albedo3 = pow3(albedo.rgb);
    float lAlbedo3 = clamp(length(albedo3), 0.0, 1.0);
    float smoothness = 0.0;
    #ifdef GENERATED_SPECULAR_ON_ALL_BLOCKS //Base reflectance for all materials
    smoothness += 0.03 * lAlbedo * (1.0 - float(subsurface > 0.0));
    #endif

    #include "/lib/pbr/blocks/amethyst_block.glsl"
    #include "/lib/pbr/blocks/amethyst.glsl"
    #include "/lib/pbr/blocks/anvil.glsl"
    #include "/lib/pbr/blocks/beacon.glsl"
    #include "/lib/pbr/blocks/black_materials.glsl"
    #include "/lib/pbr/blocks/brewing_stand.glsl"
    #include "/lib/pbr/blocks/bricks.glsl"
    #include "/lib/pbr/blocks/calcite.glsl"
    #include "/lib/pbr/blocks/candles_corals.glsl"
    #include "/lib/pbr/blocks/cave_berries.glsl"
    #include "/lib/pbr/blocks/chorus.glsl"
    #include "/lib/pbr/blocks/concrete.glsl"
    #include "/lib/pbr/blocks/copper_emitters.glsl"
    #include "/lib/pbr/blocks/copper.glsl"
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
    #include "/lib/pbr/blocks/nether_bricks.glsl"
    #include "/lib/pbr/blocks/nether_logs.glsl"
    #include "/lib/pbr/blocks/nether_plants.glsl"
    #include "/lib/pbr/blocks/note_block.glsl"
    #include "/lib/pbr/blocks/obsidian.glsl"
    #include "/lib/pbr/blocks/planks.glsl"
    #include "/lib/pbr/blocks/polished_materials.glsl"
    #include "/lib/pbr/blocks/powered_rail.glsl"
    #include "/lib/pbr/blocks/prismarine.glsl"
    #include "/lib/pbr/blocks/purpur.glsl"
    #include "/lib/pbr/blocks/quartz.glsl"
    #include "/lib/pbr/blocks/raw_metals.glsl"
    #include "/lib/pbr/blocks/redstone_lamp.glsl"
    #include "/lib/pbr/blocks/redstone_ore.glsl"
    #include "/lib/pbr/blocks/reflective_materials.glsl"
    #include "/lib/pbr/blocks/sand.glsl"
    #include "/lib/pbr/blocks/sculk.glsl"
    #include "/lib/pbr/blocks/soul_emitters.glsl"
    #include "/lib/pbr/blocks/spawner.glsl"
    #include "/lib/pbr/blocks/stripped_logs.glsl"
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

    #ifdef TEXTURED_FIRE_LAVA
    #include "/lib/pbr/blocks/fire.glsl"
    #include "/lib/pbr/blocks/lava.glsl"
    #endif

    #ifdef GENERATED_EMISSION
    emission = clamp(emission, 0.0, 1.0);
    #else
    emission = 0.0;
    #endif

    #ifdef GENERATED_SPECULAR
    smoothness2 = clamp(smoothness, 0.0, 0.95) * (1.0 - emission);
    #endif
}
#endif

#ifdef GBUFFERS_ENTITIES
void generateIPBR(inout vec4 albedo, in vec3 worldPos, in vec3 viewPos, inout vec2 lightmap, inout float emission, inout float smoothness, inout float metalness, inout float subsurface) {
    float lAlbedo = clamp(length(albedo.rgb), 0.0, 1.0);
    float material = currentRenderedItemId - 10000.0;

    //Entities
    #include "/lib/pbr/entities/creaking.glsl"
    #include "/lib/pbr/entities/drowned.glsl"
    #include "/lib/pbr/entities/end_crystal.glsl"
    #include "/lib/pbr/entities/end_dragon.glsl"
    #include "/lib/pbr/entities/experience_bottle.glsl"
    #include "/lib/pbr/entities/experience_orb.glsl"
    #include "/lib/pbr/entities/glow_squid.glsl"
    #include "/lib/pbr/entities/hoglin.glsl"
    #include "/lib/pbr/entities/item_frame.glsl"
    #include "/lib/pbr/entities/magma_cube.glsl"
    #include "/lib/pbr/entities/witch.glsl"
    #include "/lib/pbr/entities/metals.glsl"

    //Items in frames
    #include "/lib/pbr/items/amethyst.glsl"
    #include "/lib/pbr/items/brewing_stand.glsl"
    #include "/lib/pbr/items/chorus.glsl"
    #include "/lib/pbr/items/crying_obsidian.glsl"
    #include "/lib/pbr/items/enchanting_table.glsl"
    #include "/lib/pbr/items/flowers.glsl"
    #include "/lib/pbr/items/froglights.glsl"
    #include "/lib/pbr/items/full_emitters.glsl"
    #include "/lib/pbr/items/glow_berries.glsl"
    #include "/lib/pbr/items/glow_lichen_sea_pickle.glsl"
    #include "/lib/pbr/items/jack_o_lantern.glsl"
    #include "/lib/pbr/items/lava.glsl"
    #include "/lib/pbr/items/magma_block_blaze_rod.glsl"
    #include "/lib/pbr/items/nether_logs.glsl"
    #include "/lib/pbr/items/ores.glsl"
    #include "/lib/pbr/items/redstone.glsl"
    #include "/lib/pbr/items/soul_emitters.glsl"
    #include "/lib/pbr/items/torch_lantern.glsl"

    #ifdef EMISSIVE_ARMOR_TRIMS
    #include "/lib/pbr/entities/trims.glsl"
    #endif

    #ifdef GENERATED_SPECULAR
    metalness = smoothness;
    #endif

    #ifdef GENERATED_EMISSION
    emission = clamp(emission, 0.0, 1.0);
    #else
    emission = 0.0;
    #endif
}
#endif

#ifdef GBUFFERS_HAND
void generateIPBR(inout vec4 albedo, in vec3 worldPos, in vec3 viewPos, inout vec2 lightmap, inout float emission, inout float smoothness, inout float metalness, inout float subsurface) {
    float lAlbedo = clamp(length(albedo.rgb), 0.0, 1.0);

    //#include "/lib/pbr/hand/metals.glsl"
    #include "/lib/pbr/items/amethyst.glsl"
    #include "/lib/pbr/items/brewing_stand.glsl"
    #include "/lib/pbr/items/chorus.glsl"
    #include "/lib/pbr/items/crying_obsidian.glsl"
    #include "/lib/pbr/items/enchanting_table.glsl"
    #include "/lib/pbr/items/flowers.glsl"
    #include "/lib/pbr/items/froglights.glsl"
    #include "/lib/pbr/items/full_emitters.glsl"
    #include "/lib/pbr/items/glow_berries.glsl"
    #include "/lib/pbr/items/glow_lichen_sea_pickle.glsl"
    #include "/lib/pbr/items/jack_o_lantern.glsl"
    #include "/lib/pbr/items/lava.glsl"
    #include "/lib/pbr/items/magma_block_blaze_rod.glsl"
    #include "/lib/pbr/items/nether_logs.glsl"
    #include "/lib/pbr/items/ores.glsl"
    #include "/lib/pbr/items/redstone.glsl"
    #include "/lib/pbr/items/soul_emitters.glsl"
    #include "/lib/pbr/items/torch_lantern.glsl"

    #ifdef GENERATED_SPECULAR
    metalness = smoothness;
    #endif

    #ifdef GENERATED_EMISSION
    emission = clamp(emission, 0.0, 1.0);
    #else
    emission = 0.0;
    #endif
}
#endif