//huge thanks to lvutner, belmu and niemand for help!

const uint k = 1103515245U;

vec3 hash(uvec3 x){
    x = ((x >> 8U) ^ x.yzx) * k;
    x = ((x >> 8U) ^ x.yzx) * k;
    x = ((x >> 8U) ^ x.yzx) * k;
    
    return vec3(x) * (1.0 / float(0xffffffffU));
}

vec3 ToScreen(in vec3 view) {
    vec4 temp = gbufferProjection * vec4(view, 1.0);
    temp.xyz /= temp.w;

    return temp.xyz * 0.5 + 0.5;
}

vec3 ToView(vec3 screen) {
    vec4 clip = vec4(screen, 1.0) * 2.0 - 1.0;
    clip = gbufferProjectionInverse * clip;
    clip.xyz /= clip.w;

    return clip.xyz;
}

/*
Credits to Zombye for this raytracer
MIT License

Copyright (c) 2017-2018 Jacob Eriksson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

float AscribeDepth(float depth, float ascribeAmount) {
	depth = 1.0 - 2.0 * depth;
	depth = (depth + gbufferProjection[2].z * ascribeAmount) / (1.0 + ascribeAmount);

	return 0.5 - 0.5 * depth;
}

float MinOf(vec3 x) { return min(min(x.x, x.y), x.z); }

vec2 viewResolution = vec2(viewWidth, viewHeight);
vec2 pixelSize = 1.0 / viewResolution;

bool IntersectSSRay(inout vec3 hitPos, vec3 currentPos, vec3 rayDir, float dither) {
	vec3 rayStep  = currentPos + abs(currentPos.z) * rayDir;
	     rayStep  = ToScreen(rayStep) - hitPos;
	     rayStep *= MinOf((step(0.0, rayStep) - hitPos) / rayStep);

	hitPos.xy *= viewResolution;
	rayStep.xy *= viewResolution;

	rayStep /= max(abs(rayStep.x), abs(rayStep.y));

	dither = floor(SSPT_STRIDE * dither + 1.0);

	vec3 stepsToEnd = (step(0.0, rayStep) * vec3(viewResolution - 1.0, 1.0) - hitPos) / rayStep;
	     stepsToEnd.z += SSPT_STRIDE;
	float tMax = min(MinOf(stepsToEnd), max(viewResolution.x, viewResolution.y));

	vec3 rayOrigin = hitPos;

	float ascribeAmount = SSPT_DEPTH_LENIENCY * SSPT_STRIDE * pixelSize.y * gbufferProjectionInverse[1].y;

	bool hit = false;
	float t = dither;
	while (t < tMax && !hit) {
		float stepStride = t == dither ? dither : SSPT_STRIDE;

		hitPos = rayOrigin + t * rayStep;
		float maxZ = hitPos.z;
		float minZ = hitPos.z - stepStride * abs(rayStep.z);

		float depth = texelFetch(depthtex1, ivec2(hitPos.xy), 0).x;
		float ascribedDepth = AscribeDepth(depth, ascribeAmount);

		hit = maxZ >= depth && minZ <= ascribedDepth;
		hit = hit && depth < 1.0;

		if (!hit) t += SSPT_STRIDE;
	}

	hitPos.xy *= pixelSize;

	return hit;
}

vec3 generateCosineVector(vec3 vector, vec2 hash) {
    hash.x *= 6.2831853;
    hash.y = hash.y * 2.0 - 1.0;
    vec3 dir = vec3(vec2(sin(hash.x), cos(hash.x)) * sqrt(1.0 - hash.y * hash.y), hash.y);

    return normalize(vector + dir);
}

vec3 computeSSPT(vec3 screenPos, vec3 normal, float hand) {
	float speed = 0.6180339887498967 * (frameCounter & 127);

    float dither = getBlueNoise(gl_FragCoord.xy);
          dither = fract(dither + speed);

    vec2 noise = hash(uvec3(gl_FragCoord.xy, speed)).xy;

    vec3 illumination = vec3(0.0);
    vec3 weight = vec3(1.0);

    vec3 hitNormal = normalize(DecodeNormal(texture2D(colortex5, screenPos.xy).xy));
    vec3 currentPos = ToView(screenPos) + hitNormal * 0.001;
    vec3 hitPos = ToScreen(currentPos);
    vec3 rayDir = generateCosineVector(hitNormal, noise);

    bool hit = IntersectSSRay(hitPos, currentPos, rayDir, dither);
    currentPos = hitPos;

    if (hit && hand < 0.5) {
        vec3 hitAlbedo = texture2D(colortex0, currentPos.xy).rgb;
        float isEmissive = texture2D(colortex5, currentPos.xy).a;

        weight *= hitAlbedo;
        illumination += weight * isEmissive;
    }

    return illumination;
}