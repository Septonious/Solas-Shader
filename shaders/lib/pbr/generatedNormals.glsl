//Generated normals based on those from Emin#7309's Complementary Shaders. Tysm for allowing me to use them a YEAR prior to me actually implementing them in my shader
float getAlbedoDifference(float lAlbedo, vec2 offsetCoord) {
    float lNearbyAlbedo = length(texture2D(tex, offsetCoord).rgb);
    float albedoDifference = lAlbedo - lNearbyAlbedo;

    if (albedoDifference > 0.0) return clamp(max(albedoDifference - 0.05, 0.0), -NORMAL_THRESHOLD, NORMAL_THRESHOLD);
    else return clamp(min(albedoDifference + 0.05, 0.0), -NORMAL_THRESHOLD, NORMAL_THRESHOLD);
}

void generateNormals(inout vec3 newNormal, vec3 albedo, vec3 viewPos, in int mat) {
    float NoU = clamp(dot(newNormal, upVec), 0.0, 1.0);
    float viewDistance = clamp(length(viewPos) * 0.01, 0.0, 1.0);
    float disableNormal = float(mat == 30000) * NoU + viewDistance;

    if (disableNormal < 0.75) {
        float lAlbedo = length(albedo);

        vec2 midCoord = texCoord - absMidCoordPos * signMidCoordPos;
        vec2 maxOffsetCoord = midCoord + absMidCoordPos;
        vec2 minOffsetCoord = midCoord - absMidCoordPos;
        vec2 resolutionOffset = (16.0 / atlasSize) / NORMAL_RESOLUTION;

        vec3 normalMap = vec3(0.0, 0.0, 1.0);

        vec2 offsetCoord = texCoord + vec2(resolutionOffset.x, 0.0);
        if (offsetCoord.x < maxOffsetCoord.x) normalMap.x += getAlbedoDifference(lAlbedo, offsetCoord);
                
        offsetCoord = texCoord + vec2(-resolutionOffset.x, 0.0);
        if (offsetCoord.x > minOffsetCoord.x) normalMap.x -= getAlbedoDifference(lAlbedo, offsetCoord);

        offsetCoord = texCoord + vec2(0.0, resolutionOffset.y);
        if (offsetCoord.y < maxOffsetCoord.y) normalMap.y += getAlbedoDifference(lAlbedo, offsetCoord);

        offsetCoord = texCoord + vec2(0.0, -resolutionOffset.y);
        if (offsetCoord.y > minOffsetCoord.y) normalMap.y -= getAlbedoDifference(lAlbedo, offsetCoord);

        normalMap.xy = clamp(normalMap.xy * NORMAL_STRENGTH, -0.5, 0.5);

        if (normalMap.xy != vec2(0.0)) {
            mat3 tbnMatrix = mat3(
                tangent.x, binormal.x, normal.x,
                tangent.y, binormal.y, normal.y,
                tangent.z, binormal.z, normal.z
            );

            newNormal = clamp(normalize(normalMap * tbnMatrix), -1.0, 1.0);
        }
    }
}