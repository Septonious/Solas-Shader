const int RADIUS = 16;
const float KERNEL[] = float[](
   0.000030517578125,
   0.000457763671875,
   0.003204345703125,
   0.013885498046875,
   0.041656494140625,
   0.091644287109375,
   0.152740478515625,
   0.196380615234375,
   0.196380615234375,
   0.152740478515625,
   0.091644287109375,
   0.041656494140625,
   0.013885498046875,
   0.003204345703125,
   0.000457763671875,
   0.000030517578125
);

vec3 gaussianBlur(sampler2D colortex, vec2 coord, vec2 direction) {
    vec2 pixelSize = 1.0 / vec2(viewWidth, viewHeight);
    vec3 blur = vec3(0.0);
    
    for (int i = -15; i < 15; i++) {
        float weight = KERNEL[abs(i)];
        blur += texture2D(colortex, coord + direction * pixelSize * float(i)).rgb * weight;
    }
    
    return blur;
}