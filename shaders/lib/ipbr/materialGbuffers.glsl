void getMaterials(out float smoothness, out float metalness, out float f0, inout float emission,
                  out float subsurface, out float porosity, out float ao, out vec3 newNormal,
                  vec2 newCoord, vec2 dcdx, vec2 dcdy, mat3 tbnMatrix) {
    //OldPBR
    #if MATERIAL_FORMAT == 0
    #ifdef PARALLAX
    vec4 specularMap = texture2DGradARB(specular, newCoord, dcdx, dcdy);
    #else
    vec4 specularMap = texture2D(specular, texCoord);
    #endif
    
    f0 = 0.04;
    ao = 1.0;
    smoothness = specularMap.r;
    metalness = specularMap.g;
    porosity = 0.5 - 0.5 * smoothness;
    subsurface = specularMap.a > 0.0 ? 1.0 - specularMap.a : 0.0;

    float emissionMat = specularMap.b * specularMap.b;

    #ifdef PARALLAX
	vec3 normalMap = texture2DGradARB(normals, newCoord, dcdx, dcdy).xyz * 2.0 - 1.0;
    #else
	vec3 normalMap = texture2D(normals, texCoord).xyz * 2.0 - 1.0;
    #endif

    if (normalMap.x + normalMap.y < -1.999) normalMap = vec3(0.0, 0.0, 1.0);
    #endif

    //LabPBR 1.3
    #if MATERIAL_FORMAT == 1
    vec4 specularMap = texture2D(specular, newCoord);

    f0 = specularMap.g;
    smoothness = specularMap.r;
    metalness = f0 >= 0.9 ? 1.0 : 0.0;
    porosity = specularMap.b <= 0.251 ? specularMap.b * 3.984 : 0.0;
    subsurface = specularMap.b > 0.251 ? clamp(specularMap.b * 1.335 - 0.355, 0.0, 1.0) : 0.0;

    float emissionMat = specularMap.a < 1.0 ? clamp(specularMap.a * 1.004 - 0.004, 0.0, 1.0) : 0.0;
          emissionMat *= emissionMat;

    #ifdef PARALLAX
	vec3 normalMap = vec3(texture2DGradARB(normals, newCoord, dcdx, dcdy).xy, 0.0) * 2.0 - 1.0;
    ao = texture2DGradARB(normals, newCoord, dcdx, dcdy).z;
    #else
	vec3 normalMap = vec3(texture2D(normals, texCoord).xy, 0.0) * 2.0 - 1.0;
    ao = texture2D(normals, texCoord).z;
    #endif

    if (normalMap.x + normalMap.y > -1.999) {
        if (length(normalMap.xy) > 1.0) {
            normalMap.xy = normalize(normalMap.xy);
        }

        normalMap.z = sqrt(1.0 - dot(normalMap.xy, normalMap.xy));
        normalMap = normalize(clamp(normalMap, vec3(-1.0), vec3(1.0)));
    } else {
        normalMap = vec3(0.0, 0.0, 1.0);
        ao = 1.0;
    }
    #endif

    emission = emissionMat;

	if (normalMap.x > -0.999 || normalMap.y > -0.999) newNormal = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
}