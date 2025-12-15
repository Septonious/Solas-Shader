float getNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

void drawStars(inout vec3 color, in vec3 worldPos, in float VoU, in float VoS, in float caveFactor, in float nebulaFactor, in float occlusion, in float size) {
	#ifdef OVERWORLD
	float visibility = moonVisibility * (1.0 - wetness) * pow(VoU, 0.5) * caveFactor;
	#else
	float visibility = 1.0;
	#endif

	visibility *= 1.0 - occlusion;

	if (0 < visibility) {
		vec2 planeCoord = worldPos.xz / (length(worldPos.y) + length(worldPos.xyz));
			 planeCoord *= size;
			 #ifdef END_BLACK_HOLE
			 float baseRing = pow10(pow32(VoS));

			 planeCoord *= clamp(1.0 - baseRing * 4.0, 0.0, 1.0);
			 planeCoord += baseRing;
			 #endif
			 planeCoord += cameraPosition.xz * 0.00001;
			 planeCoord += frameTimeCounter * 0.001;
		const float amount = STAR_AMOUNT;
		vec2 planeCoord0 = floor(planeCoord * 500.0 * amount) / (500.0 * amount);
		vec2 planeCoord1 = floor(planeCoord * 1000.0 * amount) / (1000.0 * amount);

		float starNoise = getNoise(planeCoord0 + 8.0);
			  starNoise*= getNoise(planeCoord1 + 14.0);

        float stars = clamp(starNoise - (0.825 - nebulaFactor * 0.125), 0.0, 1.0);
			  stars *= stars * stars * 512.0;
			  stars = clamp(stars, 0.0, 16.0);

		#ifdef OVERWORLD
		color += (stars + pow2(max(starNoise - 0.95, 0.0)) * 2048.0) * lightNight * visibility * STAR_BRIGHTNESS;
		#else
		#ifdef END_BLACK_HOLE
		float hole = pow(pow4(pow32(VoS)), END_BLACK_HOLE_SIZE);
		hole *= hole;

		stars *= 1.0 - hole;
		#endif

		color = mix(color, color * (4.0 + pow4(stars)) * visibility * STAR_BRIGHTNESS, min(1.0, stars));
		#endif
	}
}

// Shooting stars implementation based on https://www.shadertoy.com/view/ttVXDy and also based on https://github.com/OUdefie17/Photon-GAMS
// Credits to SpacEagle17 for allowing me to use shooting stars from his Euphoria Patches shader :P

#ifdef SHOOTING_STARS
const vec2 startPositions[10] = vec2[](
    vec2(-0.4, 0.3),
    vec2(0.2, 0.4),
    vec2(-0.1, -0.3),
    vec2(0.3, -0.2),
    vec2(-0.3, 0.1),
    vec2(0.5, 0.2),
    vec2(-0.5, -0.1),
    vec2(0.1, 0.5),
    vec2(-0.2, -0.4),
    vec2(0.4, -0.3)
);

const vec2 directions[10] = vec2[](
    vec2(0.7071, 0.7071),
    vec2(0.7071, -0.7071),
    vec2(-1.0, 0.0),
    vec2(1.0, 0.0),
    vec2(0.5299, 0.8480),
    vec2(-0.6000, 0.8000),
    vec2(0.9134, -0.4067),
    vec2(-0.8000, -0.6000),
    vec2(0.3015, 0.9535),
    vec2(-0.2000, -0.9798)
);

// Calculate distance from point p to line segment from a to b
float DistLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * t);
}

// Draw a line with smooth edges
float DrawLine(vec2 p, vec2 a, vec2 b) {
    float d = DistLine(p, a, b);
    float m = smoothstep(SHOOTING_STARS_LINE_THICKNESS * 0.01, 0.00001, d);
    float d2 = length(a - b);
    m *= smoothstep(1.0, 0.5, d2) + smoothstep(0.04, 0.03, abs(d2 - 0.75));
    return m;
}

float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

mat2 rotate(float angle) {
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c);
}

// Generate a single shooting star
float drawShootingStar(vec2 uv, vec2 startPos, vec2 direction) {
    vec2 id = floor(uv * 0.5);
    float h = hash12(id);
    float worldDayFactor = abs(worldDay % 7 - worldDay % 5 * 0.5) / 6.0;

    if (h >= pow(SHOOTING_STARS_CHANCE * worldDayFactor * 0.05, 1.5)) return 0.0;

    vec2 gv = fract(uv * 0.5) * 2.0 - 1.0;
    float line = DrawLine(gv, startPos, startPos + direction * 0.9);

    vec2 toStart = gv - startPos;
    float alongTrail = dot(toStart, direction);
    float trail = smoothstep(SHOOTING_STARS_TRAIL_LENGTH, -0.1, alongTrail);

    float headBrightness = 1.0 + 3.0 / (1.0 + pow2((alongTrail - 1.0) * 8.0));

    return line * trail * headBrightness;
}

void getShootingStars(inout vec3 color, in vec3 worldPos, float VoU, float VoS) {
    float burnTime = max(cos(sin(frameTimeCounter * 0.35) * 4.0 + frameTimeCounter * 0.25), 0.0) * 10.0;
	float visibility = moonVisibility * (1.0 - wetness) * VoU * caveFactor * burnTime;

    if (visibility > 0.01) {
        vec2 planeCoord = worldPos.xz / (length(worldPos.y) + length(worldPos.xz) * 0.25);
        vec2 uv = planeCoord * 8.0 * (1.0 - SHOOTING_STARS_SIZE);
        float speed = frameTimeCounter * SHOOTING_STARS_SPEED;

        float stars = 0.0;
        int dayIndex = int(worldDay) % 10;
        vec2 todayDirection = directions[dayIndex];

        for (int i = 0; i < SHOOTING_STARS_COUNT; i++) {
            float offsetAngle = (hash12(vec2(i, worldDay)) - 0.5) * 0.66;
            vec2 starDirection = rotate(offsetAngle) * todayDirection;

            vec2 offsetUV = uv + starDirection * speed * (0.8 + 0.04 * float(i));
            stars += drawShootingStar(offsetUV, startPositions[i], starDirection);
        }

        float intensity = min(stars * visibility * 10.0, 1.0);
        color += vec3(0.38, 0.4, 0.5) * intensity;
    }
}
#endif