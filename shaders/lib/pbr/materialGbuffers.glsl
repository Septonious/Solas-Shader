void getMaterials(out float smoothness, out float metalness, out float f0, inout float emission,
                  inout float subsurface, out float porosity, out float ao, inout vec3 newNormal,
                  vec2 newCoord, vec2 dcdx, vec2 dcdy, mat3 tbnMatrix) {
    vec3 normalMap = vec3(0.0, 0.0, 1.0);

    #if MATERIAL_FORMAT == 0
    #ifdef PARALLAX
    vec4 specularMap = texture2DGradARB(specular, newCoord, dcdx, dcdy);
    normalMap = texture2DGradARB(normals, newCoord, dcdx, dcdy).xyz * 2.0 - 1.0;
    #else
    vec4 specularMap = texture2D(specular, texCoord);
    normalMap = texture2D(normals, texCoord).xyz * 2.0 - 1.0;
    #endif

    smoothness = specularMap.r;
    f0 = 0.04;
    metalness = specularMap.g;
    porosity = 0.5 - 0.5 * smoothness;
    ao = 1.0;

    float emissionMat = specularMap.b * specularMap.b;
    float subsurfaceMat = specularMap.a > 0.0 ? 1.0 - specularMap.a : 0.0;

    if (normalMap.x + normalMap.y < -1.999) normalMap = vec3(0.0, 0.0, 1.0);
    #endif

    #if MATERIAL_FORMAT == 1
    #ifdef PARALLAX
    vec4 specularMap = texture2DGradARB(specular, newCoord, dcdx, dcdy);
    vec4 normalTex = texture2DGradARB(normals, newCoord, dcdx, dcdy);
    #else
    vec4 specularMap = texture2D(specular, texCoord);
    vec4 normalTex = texture2D(normals, texCoord);
    #endif

    smoothness = specularMap.r;
    f0 = specularMap.g;
    metalness = f0 >= 0.9 ? 1.0 : 0.0;
    porosity = specularMap.b <= 0.251 ? specularMap.b * 3.984 : 0.0;

    float emissionMat = specularMap.a < 1.0 ? clamp(specularMap.a * 1.004 - 0.004, 0.0, 1.0) : 0.0;
    emissionMat *= emissionMat;
    float subsurfaceMat = specularMap.b > 0.251 ? clamp(specularMap.b * 1.335 - 0.355, 0.0, 1.0) : 0.0;

    normalMap = vec3(normalTex.xy, 0.0) * 2.0 - 1.0;
    ao = normalTex.z;

    if (normalMap.x + normalMap.y > -1.999) {
        if (length(normalMap.xy) > 1.0) normalMap.xy = normalize(normalMap.xy);
        normalMap.z = sqrt(max(1.0 - dot(normalMap.xy, normalMap.xy), 0.0));
        normalMap = normalize(clamp(normalMap, vec3(-1.0), vec3(1.0)));
    } else {
        normalMap = vec3(0.0, 0.0, 1.0);
        ao = 1.0;
    }
    #endif

    #if EMISSIVE == 2
    emission = mix(emissionMat, 1.0, emission);
    #else
    emission = max(emission, emissionMat);
    #endif
    subsurface = max(subsurface, subsurfaceMat);

    #ifdef NORMAL_DAMPENING
    vec2 mipx = dcdx * atlasSize;
    vec2 mipy = dcdy * atlasSize;
    float delta = max(dot(mipx, mipx), dot(mipy, mipy));
    float miplevel = max(0.25 * log2(delta), 0.0);
    normalMap = normalize(mix(vec3(0.0, 0.0, 1.0), normalMap, 1.0 / exp2(miplevel)));
    #endif

    if ((normalMap.x > -0.999 || normalMap.y > -0.999) && newNormal == newNormal) {
        newNormal = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
    }
}

vec3 getPBRFresnel(vec3 albedoColor, vec3 normal, vec3 viewPos, float smoothness, float metalness, float f0, float ao) {
    vec3 rawAlbedo = pow(max(albedoColor, vec3(0.0)), vec3(2.2)) * 0.999 + 0.001;
    float fresnel = pow(clamp(1.0 + dot(normal, normalize(viewPos)), 0.0, 1.0), 5.0);
    vec3 baseReflectance = vec3(max(f0 * f0 * 0.08, 0.02));
    vec3 fresnel3 = mix(baseReflectance, vec3(1.0), fresnel);

    if (metalness > 0.5) {
        if (f0 >= 0.9) {
            fresnel3 = complexFresnel(pow(fresnel, 0.2), f0);
        } else {
            fresnel3 = rawAlbedo;
        }
        fresnel3 *= rawAlbedo;
    }

    float aoSquared = ao * ao;
    fresnel3 *= aoSquared;

    return clamp(fresnel3, vec3(0.0), vec3(1.0));
}
