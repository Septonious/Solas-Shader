#ifdef LPV_FOG
uniform vec4 lightningBoltPosition;

float lightningFlashEffect(vec3 worldPos, vec3 lightningBoltPosition, float lightDistance){ //Thanks to Xonk!
    vec3 lightningPos = worldPos - vec3(lightningBoltPosition.x, max(worldPos.y, lightningBoltPosition.y), lightningBoltPosition.z);

    float lightningLight = max(1.0 - length(lightningPos) / lightDistance, 0.0);
          lightningLight = exp(-24.0 * (1.0 - lightningLight));

    return lightningLight;
}

float getLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

void computeLPVFog(inout vec3 fog, in vec3 translucent, in float dither) {
    vec3 lightFog = vec3(0.0);

	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	//Total LPV Fog Visibility
    float visibility = int(z0 > 0.56) * float(isEyeInWater >= 0 && isEyeInWater <= 1);

	#ifdef OVERWORLD
	visibility *= 1.0 - timeBrightness * 0.65 * caveFactor;
	visibility = mix(1.0, visibility, caveFactor);
	#endif

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

    //Ray Marching Parameters
    float minDist = 6.0;
    #ifdef OVERWORLD
          minDist += 4.0 * eBS;
    #endif
    float maxDist = min(far, VOXEL_VOLUME_SIZE * 0.5);
    int sampleCount = min(int(maxDist / minDist + 0.01), 14 - int(eBS * sunVisibility * sunVisibility * 14));

    if (sampleCount > 0 && visibility > 0) {
        //LPV Fog Intensity
        float intensity = 150.0;
        float density = 0.75;
        #ifdef OVERWORLD
            intensity *= 1.0 - sunVisibility * eBS * 0.5;
            density *= 0.75 + sunVisibility * eBS * 0.25;

            intensity += wetness * eBS * 50.0;
            density -= wetness * eBS * 0.25;

            intensity = mix(400.0, intensity, caveFactor);
            density = mix(0.4, density, caveFactor);
        #endif
        #ifdef NETHER
            intensity = 150.0;
            density = 0.7;
        #endif

        //Positions
        vec3 viewPosZ0 = ToView(vec3(texCoord.xy, z0));
        vec3 viewPosZ1 = ToView(vec3(texCoord.xy, z1));
        vec3 worldPos = ToWorld(viewPosZ1);

        float lViewPosZ0 = length(viewPosZ0);
        float lViewPosZ1 = length(viewPosZ1);

        //Ray Marching
        vec3 rayIncrement = normalize(worldPos) * minDist;
        vec3 rayPos = rayIncrement * dither;

        for (int i = 0; i < sampleCount; i++, rayPos += rayIncrement) {
            float rayLength = length(rayPos);
            if (rayLength > lViewPosZ1) break;

            vec3 voxelPos = worldToVoxel(rayPos);
                voxelPos /= voxelVolumeSize;
                voxelPos = clamp(voxelPos, 0.0, 1.0);

            vec4 lightVolume = vec4(0.0);
            if ((frameCounter & 1) == 0) {
                lightVolume = texture(floodfillSamplerCopy, voxelPos);
            } else {
                lightVolume = texture(floodfillSampler, voxelPos);
            }

            vec3 lightSample = pow(lightVolume.rgb, vec3(1.0 / FLOODFILL_RADIUS));

            #ifdef NETHER_CLOUDY_FOG
            vec3 npos = (rayPos + cameraPosition) * VF_NETHER_FREQUENCY + vec3(frameTimeCounter * VF_NETHER_SPEED, 0.0, 0.0);

            float n3da = texture2D(noisetex, npos.xz * 0.001 + floor(npos.y * 0.1) * 0.2).r;
            float n3db = texture2D(noisetex, npos.xz * 0.001 + floor(npos.y * 0.1 + 1.0) * 0.2).r;

            float cloudyNoise = mix(n3da, n3db, fract(npos.y * 0.1));
                cloudyNoise = max(cloudyNoise - 0.45, 0.0);
                cloudyNoise = min(cloudyNoise * 8.0, 1.0);
                cloudyNoise = cloudyNoise * (1.0 + cloudyNoise * cloudyNoise);
            lightSample = lightSample * (0.75 + cloudyNoise) + cloudyNoise * netherCol * VF_NETHER_STRENGTH / sampleCount;
            #endif

            #ifdef LPV_CLOUDY_FOG
            vec3 npos = (rayPos + cameraPosition) * 6.0 + vec3(frameTimeCounter, 0.0, 0.0);

            float n3da = texture2D(noisetex, npos.xz * 0.001 + floor(npos.y * 0.1) * 0.1).r;
            float n3db = texture2D(noisetex, npos.xz * 0.001 + floor(npos.y * 0.1 + 1.0) * 0.1).r;

            float cloudyNoise = mix(n3da, n3db, fract(npos.y * 0.1));
                cloudyNoise = max(cloudyNoise - 0.45, 0.0);
                cloudyNoise = min(cloudyNoise * 8.0, 1.0);
                cloudyNoise = cloudyNoise * (1.0 + cloudyNoise * cloudyNoise);
            lightSample *= 0.6 + cloudyNoise * 0.4;
            #endif

            float rayDistance = length(vec3(rayPos.x, rayPos.y * 2.0, rayPos.z));
            lightSample *= max(0.0, 1.0 - rayDistance / maxDist);

            if (rayLength > lViewPosZ0) lightSample *= translucent;
            lightFog += lightSample;
        }

        vec3 result = pow(lightFog / sampleCount, vec3(0.5)) * visibility;
        fog += result * pow(length(result), density) * intensity * 0.01 * LPV_FOG_STRENGTH;
    }
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

vec3 calculateMovement(vec3 worldPos, float lightIntensity, float speed, vec2 mult) {
    vec3 wave = calculateWaving(worldPos * lightIntensity, frameTimeCounter * speed);

    return wave * vec3(mult, mult.x);
}

void computeFireflies(inout float fireflies, in vec3 translucent, in float dither) {
	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

    //Positions
	vec3 viewPosZ0 = ToView(vec3(texCoord.xy, z0));
    vec3 viewPosZ1 = ToView(vec3(texCoord.xy, z1));
	vec3 worldPos = ToWorld(viewPosZ1);

    float lViewPosZ0 = length(viewPosZ0);
    float lViewPosZ1 = length(viewPosZ1);

	//Total fireflies visibility
	float visibility = eBS * eBS * (1.0 - sunVisibility) * (1.0 - wetness) * float(isEyeInWater == 0);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

    //Ray Marching Parameters
    float minDist = 3.0;
    float maxDist = min(far, 96.0);
    int sampleCount = int(maxDist / minDist + 0.01);

    vec3 rayIncrement = normalize(worldPos) * minDist;
    vec3 rayPos = rayIncrement * dither;

    //Ray Marching
    for (int i = 0; i < sampleCount; i++, rayPos += rayIncrement) {
        float rayLength = length(rayPos);
        if (rayLength > lViewPosZ1) break;

        vec3 nposA = rayPos + cameraPosition;
             nposA += calculateMovement(nposA, 0.6, 3.0, vec2(2.4, 1.8));
             nposA += vec3(sin(frameTimeCounter * 0.50), - sin(frameTimeCounter * 0.75), cos(frameTimeCounter * 1.25));

        float fireflyNoise = getFireflyNoise(nposA);
              fireflyNoise = clamp(fireflyNoise - 0.675, 0.0, 1.0);

        float rayDistance = length(vec3(rayPos.x, rayPos.y * 2.0, rayPos.z));
        fireflyNoise *= max(0.0, 1.0 - rayDistance / maxDist);

        if (rayLength > lViewPosZ0) break;
        fireflies += fireflyNoise * (1.0 - clamp(nposA.y * 0.01, 0.0, 1.0)) * visibility * 64.0;
    }
}
#endif