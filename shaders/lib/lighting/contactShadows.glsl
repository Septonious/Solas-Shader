float getLinearDepth(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

float getContactShadow(vec3 viewPos, vec3 rayDir, float dither) {
    int samples = 16;
    float depthLenience = 0.3;
    float rayLength = 1.0 / samples;

    vec3 rayPos = ToScreen(viewPos);
         rayDir = normalize(ToScreen(viewPos + rayDir) - rayPos);

    vec3 increment = rayDir * (depthLenience * rayLength);
         rayPos += increment * (1.0 + dither);

    for (int i = 0; i < samples; i++, rayPos += increment) {
        if (clamp(rayPos.xy, 0.0, 1.0) != rayPos.xy) return 1.0;

        float z1 = texelFetch(depthtex1, ivec2(rayPos.xy * vec2(viewWidth, viewHeight)), 0).x;

        if (z1 >= rayPos.z) return 1.0;

        z1 = getLinearDepth(z1);

        if (abs(z1 - getLinearDepth(rayPos.z)) / z1 < depthLenience) return 0.0;
    }

    return 1.0;
}
