#ifdef LPV_FOG
uniform vec4 lightningBoltPosition;

float lightningFlashEffect(vec3 worldPos, vec3 lightningBoltPosition, float lightDistance){ //Thanks to Xonk!
    vec3 lightningPos = worldPos - vec3(lightningBoltPosition.x, max(worldPos.y, lightningBoltPosition.y), lightningBoltPosition.z);

    float lightningLight = max(1.0 - length(lightningPos) / lightDistance, 0.0);
          lightningLight = exp(-24.0 * (1.0 - lightningLight));

    return lightningLight;
}

void computeLPVFog(inout vec3 fog, in vec3 translucent, in float dither) {
    vec3 finalFog = vec3(0.0);

	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	//Positions
	vec3 viewPos = ToView(vec3(texCoord.xy, z0));

	//Total LPV Fog Visibility
    float visibility = int(z0 > 0.56);

	#ifdef OVERWORLD
	visibility *= 1.0 - timeBrightness * 0.65 * caveFactor;
	visibility = mix(1.0, visibility, caveFactor);
	#endif

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	float density = 25.0 * (0.6 + eBS * eBS * 0.4);
	#ifdef OVERWORLD
		  density = mix(density, 35.0, wetness * eBS);
		  density = mix(40.0, density, caveFactor);
	#endif
	#ifdef NETHER
		  density = 45.0;
		  visibility *= 0.6;
	#endif

	if (visibility > 0.0) {
		//Linear Depths
		float linearDepth0 = getLinearDepth2(z0);
		float linearDepth1 = getLinearDepth2(z1);

		//Variables
        int sampleCount = LPV_FOG_SAMPLES;

		float maxDist = VOXEL_VOLUME_SIZE;
		float minDist = (maxDist / sampleCount) * 0.5;
		float maxCurrentDist = min(linearDepth1, maxDist);

		//Ray Marching
		for (int i = 0; i < sampleCount; i++) {
			float currentDist = (i + dither) * minDist;

			if (currentDist > maxCurrentDist || linearDepth1 < currentDist || (linearDepth0 < currentDist && translucent.rgb == vec3(0.0))) {
				break;
			}

            vec3 worldPos = ToWorld(ToView(vec3(texCoord, getLogarithmicDepth(currentDist))));

			if (length(worldPos.xz) < VOXEL_VOLUME_SIZE) {
                float lightning = min(lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 256.0) * lightningBoltPosition.w * 4.0, 1.0);

				float floodfillFade = maxOf(abs(worldPos) / (voxelVolumeSize * 0.5));
					  floodfillFade = clamp(floodfillFade, 0.0, 1.0);

                vec3 voxelPos = ToVoxel(worldPos);

                vec3 voxelSamplePos = voxelPos;
                     voxelSamplePos /= voxelVolumeSize;
                     voxelSamplePos = clamp(voxelSamplePos, 0.0, 1.0);

                vec3 floodfillData = texture3D(floodfillSampler, voxelSamplePos).rgb;
                vec3 voxelLighting = pow(floodfillData, vec3(1.0 / FLOODFILL_RADIUS));
					 voxelLighting *= 0.5 + 0.5 * length(voxelLighting);
				vec3 lpvFog = mix(voxelLighting * density * LPV_FOG_STRENGTH, vec3(0.0), floodfillFade);

				#ifdef NETHER_CLOUDY_FOG
				vec3 npos = (worldPos + cameraPosition) * VF_NETHER_FREQUENCY + vec3(frameTimeCounter * VF_NETHER_SPEED, 0.0, 0.0);

				float n3da = texture2D(noisetex, npos.xz * 0.001 + floor(npos.y * 0.1) * 0.2).r;
				float n3db = texture2D(noisetex, npos.xz * 0.001 + floor(npos.y * 0.1 + 1.0) * 0.2).r;

				float cloudyNoise = mix(n3da, n3db, fract(npos.y * 0.1));
					  cloudyNoise = max(cloudyNoise - 0.45, 0.0);
					  cloudyNoise = min(cloudyNoise * 8.0, 1.0);
				lpvFog += cloudyNoise * (1.0 + cloudyNoise * cloudyNoise) * netherColSqrt * VF_NETHER_STRENGTH;
				#endif

				//Translucency Blending
				if (linearDepth0 < currentDist) {
					lpvFog *= translucent.rgb;
				}

                float currentSampleIntensity = (currentDist / maxDist) / sampleCount;

				finalFog += lpvFog * currentSampleIntensity;
			}
		}
		finalFog *= visibility;
	}

    fog += finalFog;
}
#endif

#ifdef FIREFLIES
vec3 hash(vec3 p3){
    p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return 2.0 * fract((p3.xxy + p3.yxx) * p3.zyx) - 1.0;
}

float getFireflyNoise(vec3 pos){
    pos += 1e-4 * frameTimeCounter;

    vec3 floorPos = floor(pos);
    vec3 fractPos = fract(pos);
	
	vec3 u = (fractPos * fractPos * fractPos) * (fractPos * (fractPos * 6.0 - 15.0) + 10.0);

    return mix( mix( mix( dot( hash(floorPos + vec3(0.0,0.0,0.0)), fractPos - vec3(0.0,0.0,0.0)), 
              dot( hash(floorPos + vec3(1.0,0.0,0.0)), fractPos - vec3(1.0,0.0,0.0)), u.x),
         mix( dot( hash(floorPos + vec3(0.0,1.0,0.0)), fractPos - vec3(0.0,1.0,0.0)), 
              dot( hash(floorPos + vec3(1.0,1.0,0.0)), fractPos - vec3(1.0,1.0,0.0)), u.x), u.y),
    mix( mix( dot( hash(floorPos + vec3(0.0,0.0,1.0)), fractPos - vec3(0.0,0.0,1.0)), 
              dot( hash(floorPos + vec3(1.0,0.0,1.0)), fractPos - vec3(1.0,0.0,1.0)), u.x),
         mix( dot( hash(floorPos + vec3(0.0,1.0,1.0)), fractPos - vec3(0.0,1.0,1.0)), 
              dot( hash(floorPos + vec3(1.0,1.0,1.0)), fractPos - vec3(1.0,1.0,1.0)), u.x), u.y), u.z );
}

vec3 calculateWaving(vec3 worldPos, float wind) {
    float strength = sin(wind + worldPos.z + worldPos.y) * 0.25 + 0.05;

    float d0 = sin(wind * 0.0125);
    float d1 = sin(wind * 0.0090);
    float d2 = sin(wind * 0.0105);

    return vec3(sin(wind * 0.0065 + d0 + d1 - worldPos.x + worldPos.z + worldPos.y), 
                sin(wind * 0.0225 + d1 + d2 + worldPos.x - worldPos.z + worldPos.y),
                sin(wind * 0.0015 + d2 + d0 + worldPos.z + worldPos.y - worldPos.y)) * strength;
}

vec3 calculateMovement(vec3 worldPos, float density, float speed, vec2 mult) {
    vec3 wave = calculateWaving(worldPos * density, frameTimeCounter * speed);

    return wave * vec3(mult, mult.x);
}

void computeFireflies(inout float fireflies, in vec3 translucent, in float dither) {
	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	//Positions
	vec3 viewPos = ToView(vec3(texCoord.xy, z0));

	//Total fireflies visibility
	float visibility = eBS * eBS * (1.0 - sunVisibility) * (1.0 - wetness) * float(isEyeInWater == 0);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (visibility > 0.0) {
		//Linear Depths
		float linearDepth0 = getLinearDepth2(z0);
		float linearDepth1 = getLinearDepth2(z1);

		//Variables
        int sampleCount = 6;

		float maxDist = 96.0;
		float maxCurrentDist = min(linearDepth1, maxDist);

		//Ray Marching
		for (int i = 0; i < sampleCount; i++) {
			float currentDist = (i + dither) * 4.0;

			if (currentDist > maxCurrentDist || linearDepth1 < currentDist || (linearDepth0 < currentDist && translucent.rgb == vec3(0.0))) {
				break;
			}

            vec3 worldPos = ToWorld(ToView(vec3(texCoord, getLogarithmicDepth(currentDist))));

			if (length(worldPos.xz) < maxDist) {
				vec3 nposA = worldPos + cameraPosition;
					 nposA += calculateMovement(nposA, 0.6, 3.0, vec2(2.4, 1.8));
					 nposA += vec3(sin(frameTimeCounter * 0.50), - sin(frameTimeCounter * 0.75), cos(frameTimeCounter * 1.25));

				float fireflyNoise = getFireflyNoise(nposA);
					  fireflyNoise = clamp(fireflyNoise - 0.675, 0.0, 1.0);

				fireflies += fireflyNoise * (1.0 - clamp(nposA.y * 0.01, 0.0, 1.0)) * visibility * 64.0;
			}
		}
	}
}
#endif