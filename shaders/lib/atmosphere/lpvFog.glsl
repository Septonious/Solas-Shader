uniform vec4 lightningBoltPosition;

float lightningFlashEffect(vec3 worldPos, vec3 lightningBoltPosition, float lightDistance){ //Thanks to Xonk!
    vec3 lightningPos = worldPos - vec3(lightningBoltPosition.x, max(worldPos.y, lightningBoltPosition.y), lightningBoltPosition.z);

    float lightningLight = max(1.0 - length(lightningPos) / lightDistance, 0.0);
          lightningLight = exp(-24.0 * (1.0 - lightningLight));

    return lightningLight;
}

#ifdef FIREFLIES
vec3 hash(vec3 p3){
    p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return 2.0 * fract((p3.xxy + p3.yxx) * p3.zyx) - 1.0;
}

float getWispNoise(vec3 pos){
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
#endif

void computeLPVFog(inout vec3 fog, inout float fireflies, in vec3 translucent, in float dither) {
    vec3 finalFog = vec3(0.0);
	vec3 wisps = vec3(0.0);

	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	//Positions
	vec3 viewPos = ToView(vec3(texCoord.xy, z0));

	//Total LPV Fog Visibility
    float fogVisibility = int(z0 > 0.56);

	#ifdef OVERWORLD
	fogVisibility *= 1.0 - timeBrightness * 0.5;
	fogVisibility = mix(1.0, fogVisibility, caveFactor);
	#endif

	#if MC_VERSION >= 11900
	fogVisibility *= 1.0 - darknessFactor;
	#endif

	fogVisibility *= 1.0 - blindFactor;

	float density = 14.0;
	#ifdef OVERWORLD
		  density = mix(density, 16.0, wetness * eBS);
		  density = mix(22.0, density, caveFactor);
	#endif
	#ifdef NETHER
		  density = 20.0;
		  fogVisibility *= 0.5;
	#endif

	if (fogVisibility > 0.0) {
		//Linear Depths
		float linearDepth0 = getLinearDepth(z0);
		float linearDepth1 = getLinearDepth(z1);

		//Variables
        int sampleCount = LPV_FOG_SAMPLES;

		float maxDist = 96.0;
		float maxCurrentDist = min(linearDepth1, maxDist);

		//Ray Marching
		for (int i = 0; i < sampleCount; i++) {
			float currentDist = exp2(i + dither) - 0.95;

			if (currentDist > maxCurrentDist || linearDepth1 < currentDist || (linearDepth0 < currentDist && translucent.rgb == vec3(0.0))) {
				break;
			}

            vec3 worldPos = ToWorld(ToView(vec3(texCoord, getLogarithmicDepth(currentDist))));

			if (length(worldPos.xz) < voxelVolumeSize) {
                float lightning = min(lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 256.0) * lightningBoltPosition.w * 4.0, 1.0);

                float floodfillFade = maxOf(abs(worldPos));
                      floodfillFade /= voxelVolumeSize * 0.5;
                      floodfillFade = clamp(floodfillFade, 0.0, 1.0);

                vec3 voxelPos = ToVoxel(worldPos);

                vec3 voxelSamplePos = voxelPos;
                     voxelSamplePos /= voxelVolumeSize;
                     voxelSamplePos = clamp(voxelSamplePos, 0.0, 1.0);

                vec3 floodfillData = texture3D(floodfillSampler, voxelSamplePos).rgb;
                vec3 lighting = pow(floodfillData.rgb, vec3(0.75));
				float lLighting = clamp(length(lighting), 0.0, 1.25);
        		lighting *= pow(lLighting, 0.01 + lLighting);
				vec3 lpvFog = mix(lighting * density * LPV_FOG_STRENGTH, vec3(0.0), pow3(floodfillFade));

				#ifdef NETHER_CLOUDY_FOG
				vec3 npos = (worldPos + cameraPosition) * VF_NETHER_FREQUENCY + vec3(frameTimeCounter * VF_NETHER_SPEED, 0.0, 0.0);

				float n3da = texture2D(noisetex, npos.xz * 0.001 + floor(npos.y * 0.1) * 0.2).r;
				float n3db = texture2D(noisetex, npos.xz * 0.001 + floor(npos.y * 0.1 + 1.0) * 0.2).r;

				float cloudyNoise = mix(n3da, n3db, fract(npos.y * 0.1));
					  cloudyNoise = max(cloudyNoise - 0.45, 0.0);
					  cloudyNoise = min(cloudyNoise * 8.0, 1.0);
					  cloudyNoise *= cloudyNoise;
				lpvFog += cloudyNoise * netherColSqrt * VF_NETHER_STRENGTH;
				#endif

				//Translucency Blending
				if (linearDepth0 < currentDist) {
					lpvFog *= translucent.rgb;
				}

                float currentSampleIntensity = (currentDist / maxDist) / sampleCount;

				finalFog += lpvFog * currentSampleIntensity;

				#ifdef FIREFLIES
				vec3 nposA = (worldPos + cameraPosition) + vec3(sin(frameTimeCounter) * 1.5, cos(frameTimeCounter), -frameTimeCounter);
				float wispNoise = getWispNoise(nposA * 0.75);
					  wispNoise = clamp(wispNoise - 0.6, 0.0, 1.0);

				float n3da2 = texture2D(noisetex, nposA.xz * 0.0002 + floor(nposA.y * 0.03) * 0.03).r;
				float n3db2 = texture2D(noisetex, nposA.xz * 0.0002 + floor(nposA.y * 0.03 + 1.0) * 0.03).r;
				float wispDisplacementNoise = mix(n3da2, n3db2, fract(nposA.y * 0.03));
                      wispDisplacementNoise = max(wispDisplacementNoise - 0.45, 0.0);
                      wispDisplacementNoise = clamp(wispDisplacementNoise * 4.0, 0.0, 1.0);
                      wispDisplacementNoise *= wispDisplacementNoise * wispDisplacementNoise;

				float wisps = wispNoise * wispDisplacementNoise * (1.0 - clamp(nposA.y * 0.01, 0.0, 1.0));

				fireflies += wisps * 1024.0 * eBS * (1.0 - sunVisibility);
				#endif
			}
		}
		finalFog *= fogVisibility;
	}

    fog += finalFog;
}