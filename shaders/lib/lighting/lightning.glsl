float lightningFlashEffect(vec4 lightningBoltPosition, vec3 worldPos, float skyLightMap, float lightDistance){ //Thanks to Xonk!
    vec3 lightningPos = worldPos - vec3(lightningBoltPosition.x, max(worldPos.y, lightningBoltPosition.y), lightningBoltPosition.z);

    float lightning = max(1.0 - length(lightningPos) / lightDistance, 0.0);
          lightning = exp(-24.0 * (1.0 - lightning));
          lightning = min(lightning * lightningBoltPosition.w * skyLightMap * 4.0, 1.0);

    return lightning;
}