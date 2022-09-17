//Spheremap Transform from https://aras-p.info/texts/CompactNormalStorage.html
vec2 EncodeNormal(vec3 normal) {
    float f = sqrt(normal.z * 8.0 + 8.0);

    return normal.xy / f + 0.5;
}

vec3 DecodeNormal(vec2 encodedNormal) {
    vec2 fenc = encodedNormal * 4.0 - 2.0;
    float f = dot(fenc, fenc);
    float g = sqrt(1.0 - f / 4.0);

    return vec3(fenc * g, 1.0 - f / 2.0);
}