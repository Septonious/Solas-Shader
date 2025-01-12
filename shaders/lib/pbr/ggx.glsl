#if !defined(NETHER) && !defined(DEEPERDOWN)
//GGX area light approximation from Horizon Zero Dawn
float getNoHSquared(float radiusTan, float NoL, float NoV, float VoL) {
    float radiusCos = 1.0 / sqrt(1.0 + radiusTan * radiusTan);
    
    float RoL = 2.0 * NoL * NoV - VoL;
    if (RoL >= radiusCos) return 1.0;

    float rOverLengthT = radiusCos * radiusTan / sqrt(1.0 - RoL * RoL);
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

    float triple = sqrt(clamp(1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL, 0.0, 1.0));
    
    float NoBr = rOverLengthT * triple, VoBr = rOverLengthT * (2.0 * triple * NoV);
    float NoLVTr = NoL * radiusCos + NoV + NoTr, VoLVTr = VoL * radiusCos + 1.0 + VoTr;
    float p = NoBr * VoLVTr, q = NoLVTr * VoLVTr, s = VoBr * NoLVTr;    
    float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
    float xDenom = p * p + s * ((s - 2.0 * p)) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr + 
                   q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;
    NoTr = cosTheta * NoTr + sinTheta * NoBr;
    VoTr = cosTheta * VoTr + sinTheta * VoBr;
    
    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;
    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;

    return clamp(NoH * NoH / HoH, 0.0, 1.0);
}

float GGXTrowbridgeReitz(float NoHsqr, float roughness){
    float roughnessSqr = roughness * roughness;
    float distr = NoHsqr * (roughnessSqr - 1.0) + 1.0;
    return roughnessSqr / (PI * distr * distr);
}

float SchlickGGX(float NoL, float NoV, float roughness){
    float k = roughness * 0.5;
    
    float smithL = 0.5 / (NoL * (1.0 - k) + k);
    float smithV = 0.5 / (NoV * (1.0 - k) + k);

	return smithL * smithV;
}

vec3 SphericalGaussianFresnel(float HoL, vec3 baseReflectance){
    float fresnel = exp2(((-5.55473 * HoL) - 6.98316) * HoL);
    return fresnel * (1.0 - baseReflectance) + baseReflectance;
}

vec3 GGX(vec3 normal, vec3 viewPos, float smoothness, vec3 baseReflectance, float sunSize) {
    float roughness = max(1.0 - smoothness, 0.025);
    roughness *= roughness;
    viewPos = -viewPos;
    
    vec3 halfVec = normalize(lightVec + viewPos);

    float HoL = clamp(dot(halfVec, lightVec), 0.0, 1.0);
    float NoL = clamp(dot(normal,  lightVec), 0.0, 1.0);
    float NoV = clamp(dot(normal,  viewPos), -1.0, 1.0);
    float VoL = dot(lightVec, viewPos);

    float NoHsqr = getNoHSquared(sunSize, NoL, NoV, VoL);
    if (NoV < 0.0){
        NoHsqr = dot(normal, halfVec);
        NoHsqr *= NoHsqr;
    }
    NoV = max(NoV, 0.0);
    
    float D = GGXTrowbridgeReitz(NoHsqr, roughness);
    vec3  F = SphericalGaussianFresnel(HoL, baseReflectance);
    float G = SchlickGGX(NoL, NoV, roughness);
    
    float Fl = max(length(F), 0.001);
    vec3  Fn = F / Fl;

    float specular = D * Fl * G;
    vec3 specular3 = specular / (1.0 + 0.03125 / 4.0 * specular) * Fn * NoL;

    return specular3 * 1.0 - roughness * roughness;
}

vec3 getSpecularHighlight(vec3 normal, vec3 viewPos, float smoothness, vec3 baseReflectance,
                          vec3 specularColor, vec3 shadow, float smoothLighting) {
    if (dot(shadow, shadow) < 0.00001) return vec3(0.0);

    smoothLighting *= smoothLighting;
    
    #ifdef OVERWORLD
    vec3 specular = GGX(normal, normalize(viewPos), smoothness, baseReflectance, 0.025 * sunVisibility + 0.05);
         specular *= shadow * shadowFade * smoothLighting;
         specular *= pow2(1.0 - wetness);
    #else
    vec3 specular = GGX(normal, normalize(viewPos), smoothness, baseReflectance, 0.05);
         specular *= shadow * smoothLighting;
    #endif
    
    return specular * specularColor;
}
#endif