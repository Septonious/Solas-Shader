struct Light {
    vec4 color;
    vec3 position;
    float radius;
};

layout (std140) uniform Lights {
    Light lights[2048];
};

layout (std140) uniform Env {
    int lightCount;
};

vec3 getColoredLighting(vec3 worldPos, in float blockLightMap) {
    if (blockLightMap > 0.0) {
        vec3 lightColor = vec3(0.0);
        vec3 playerPos = worldPos + cameraPosition;

        for (int i = 0; i < lightCount; i++) {
            Light l = lights[i];
            float intensity = smoothstep(0.0, 1.0, 1.0 - distance(l.position, playerPos) / l.radius);
            lightColor += l.color.rgb * l.color.a * intensity;
        }

        return clamp(lightColor * blockLightMap, 0.0, 1.0);
    }
}