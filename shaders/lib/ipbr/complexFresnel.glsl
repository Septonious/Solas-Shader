vec3 GetN(int idx) {
    if (idx == 230) return vec3(2.9114, 2.9497, 2.5845);
    if (idx == 231) return vec3(0.18299, 0.42108, 1.3734);
    if (idx == 232) return vec3(1.3456, 0.96521, 0.61722);
    if (idx == 233) return vec3(3.1071, 3.1812, 2.3230);
    if (idx == 234) return vec3(0.27105, 0.67693, 1.3164);
    if (idx == 235) return vec3(1.9100, 1.8300, 1.4400);
    if (idx == 236) return vec3(2.3757, 2.0847, 1.8453);
    if (idx == 237) return vec3(0.15943, 0.14512, 0.13547);
    return vec3(0.0);
}

vec3 GetK(int idx) {
    if (idx == 230) return vec3(3.0893, 2.9318, 2.7670);
    if (idx == 231) return vec3(3.4242, 2.3459, 1.7704);
    if (idx == 232) return vec3(7.4746, 6.3995, 5.3031);
    if (idx == 233) return vec3(3.3314, 3.3291, 3.1350);
    if (idx == 234) return vec3(3.6092, 2.6248, 2.2921);
    if (idx == 235) return vec3(3.5100, 3.4000, 3.1800);
    if (idx == 236) return vec3(4.2655, 3.7153, 3.1365);
    if (idx == 237) return vec3(3.9291, 3.1900, 2.3808);
    return vec3(1.0);
}

vec3 GetMetalCol(float f0) {
    int metalidx = int(f0 * 255.0);

    if (metalidx == 230) return vec3(0.24867, 0.22965, 0.21366);
    if (metalidx == 231) return vec3(0.88140, 0.57256, 0.11450);
    if (metalidx == 232) return vec3(0.81715, 0.82021, 0.83177);
    if (metalidx == 233) return vec3(0.27446, 0.27330, 0.27357);
    if (metalidx == 234) return vec3(0.84430, 0.48677, 0.22164);
    if (metalidx == 235) return vec3(0.36501, 0.35675, 0.37653);
    if (metalidx == 236) return vec3(0.42648, 0.37772, 0.31138);
    if (metalidx == 237) return vec3(0.91830, 0.89219, 0.83662);
    return vec3(1.0);
}

vec3 complexFresnel(float fresnel, float f0) {
    int metalidx = int(f0 * 255.0);
    vec3 k = GetK(metalidx);
    vec3 n = GetN(metalidx);
    float f = 1.0 - fresnel;

    vec3 k2 = k * k;
    vec3 n2 = n * n;
    float f2 = f * f;

    vec3 rs_num = n2 + k2 - 2 * n * f + f2;
    vec3 rs_den = n2 + k2 + 2 * n * f + f2;
    vec3 rs = rs_num / rs_den;
     
    vec3 rp_num = (n2 + k2) * f2 - 2 * n * f + 1;
    vec3 rp_den = (n2 + k2) * f2 + 2 * n * f + 1;
    vec3 rp = rp_num / rp_den;
    
    vec3 fresnel3 = clamp(0.5 * (rs + rp), vec3(0.0), vec3(1.0));
         fresnel3 *= fresnel3;

    return fresnel3;
}