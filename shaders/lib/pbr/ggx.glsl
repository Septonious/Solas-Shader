#ifndef NETHER
float getNoHSquared(float radiusTan, float NoL, float NoV, float VoL) {
    float radiusCos = inversesqrt(1.0 + radiusTan * radiusTan);

    float RoL = 2.0 * NoL * NoV - VoL;
    if (radiusCos <= RoL) return 1.0;

    float rOverLengthT = radiusCos * radiusTan / sqrt(max(1.0 - RoL * RoL, 1e-6));
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

    float triple = sqrt(clamp(1.0 - NoL*NoL - NoV*NoV - VoL*VoL + 2.0*NoL*NoV*VoL, 0.0, 1.0));

    float NoBr = rOverLengthT * triple;
    float VoBr = rOverLengthT * (2.0 * triple * NoV);

    float NoLVTr = NoL * radiusCos + NoV + NoTr;
    float VoLVTr = VoL * radiusCos + 1.0 + VoTr;

    float p = NoBr * VoLVTr;
    float q = NoLVTr * VoLVTr;
    float s = VoBr * NoLVTr;

    float xNum   = q * (-0.5*p + 0.25*VoBr*NoLVTr);
    float xDenom = p*p + s*(s - 2.0*p) + NoLVTr*((NoL*radiusCos + NoV)*VoLVTr*VoLVTr
                   + q*(-0.5*(VoLVTr + VoL*radiusCos) - 0.5));

    float twoX1    = 2.0 * xNum / (xDenom*xDenom + xNum*xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;

    NoTr = cosTheta*NoTr + sinTheta*NoBr;
    VoTr = cosTheta*VoTr + sinTheta*VoBr;

    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;
    float NoH    = NoV + newNoL;
    float HoH    = 2.0 * newVoL + 2.0;

    return clamp(NoH * NoH / HoH, 0.0, 1.0);
}

float GGXTrowbridgeReitz(float NoHsqr, float alpha2) {
    float denom = NoHsqr * (alpha2 - 1.0) + 1.0;
    return alpha2 / max(PI * denom * denom, 1e-6);
}

float SmithGGXCorrelated(float NoL, float NoV, float roughness) {
    float k  = (roughness + 1.0);
    k = k * k * 0.125;
    float GL = NoL / max(NoL * (1.0 - k) + k, 1e-6);
    float GV = NoV / max(NoV * (1.0 - k) + k, 1e-6);
    return GL * GV;
}

vec3 SchlickFresnel(float cosTheta, vec3 F0) {
    float x  = clamp(1.0 - cosTheta, 0.0, 1.0);
    float x2 = x * x;
    float x5 = x2 * x2 * x;
    return F0 + (1.0 - F0) * x5;
}

vec3 resolveF0(float f0, float metalness, vec3 albedoColor) {
    if (metalness > 0.5) {
        return albedoColor;
    } else {
        float r = f0 * f0 * 0.08;
        return vec3(r);
    }
}

vec3 getSpecularHighlight(vec3 normal, vec3 viewPos, float smoothness, float metalness,
                          vec3 albedoColor, float f0,
                          vec3 specularColor, vec3 shadow, float smoothLighting) {
    if (dot(shadow, shadow) < 0.001) return vec3(0.0);
    if (smoothness < 0.04) return vec3(0.0);

    smoothLighting *= smoothLighting;

    vec3 viewDir = -normalize(viewPos);

    #ifdef OVERWORLD
    vec3  lightDir = lightVec;
    float sunDisk  = 0.040;
    #else
    vec3  lightDir = sunVec;
    float sunDisk  = 0.150;
    #endif

    float NoL = clamp(dot(normal, lightDir), 0.0, 1.0);
    float NoV = max(dot(normal, viewDir),  0.001);
    float VoL = dot(lightDir, viewDir);

    float perceptualRoughness = 1.0 - smoothness;
    float roughness = perceptualRoughness * perceptualRoughness;
    float alpha2    = max(roughness * roughness, 0.0006);

    float NoHsqr = getNoHSquared(sunDisk, max(NoL, 0.0), NoV, VoL);

    float D = GGXTrowbridgeReitz(NoHsqr, alpha2);
    float G = SmithGGXCorrelated(max(NoL, 0.001), NoV, roughness);

    vec3 halfVec = normalize(lightDir + viewDir);
    float HoL    = clamp(dot(halfVec, lightDir), 0.0, 1.0);
    vec3  F0     = resolveF0(f0, metalness, albedoColor);
    vec3  F      = SchlickFresnel(HoL, F0);

    // Standard Cook-Torrance denominator
    vec3 specular = (D * G * F) / max(4.0 * max(NoL, 0.001) * NoV, 0.001);
    specular *= NoL;

    #ifdef OVERWORLD
    specular *= shadow * shadowFade * smoothLighting;
    #else
    specular *= shadow * smoothLighting;
    #endif

    return clamp(specular * specularColor, vec3(0.0), vec3(4.0));
}
#endif