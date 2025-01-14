#ifdef DYNAMIC_HANDLIGHT
uniform vec3 relativeEyePosition;

#include "/lib/lighting/handlight.glsl"
#endif

#ifdef VC_SHADOWS
void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float density, inout float height) {
    int worldDayInterpolated = int((worldDay * 24000 + worldTime) / 24000);
	float dayAmountFactor = abs(worldDayInterpolated % 7 / 2 - 0.5) * 0.5;
	float dayDensityFactor = abs(worldDayInterpolated % 9 / 4 - worldDayInterpolated % 2);
	float dayFrequencyFactor = 1.0 + abs(worldDayInterpolated % 6 / 4 - worldDayInterpolated % 2) * 0.65;

	amount = mix(amount, 11.5, wetness) - dayAmountFactor;
	density += dayDensityFactor;
	frequency *= dayFrequencyFactor;
}

void getCloudShadow(vec2 rayPos, vec2 wind, float amount, float frequency, float density, inout float noise) {
	rayPos *= 0.000125 * frequency;

	float noiseBase = texture2D(noisetex, rayPos + 0.5 + wind * 0.5).g;
		  noiseBase = pow2(1.0 - noiseBase) * 0.5 + 0.4 - wetness * 0.025;
	
	noise = noiseBase * 22.0;
	noise = max(noise - amount, 0.0) * (density * 0.25);
	noise /= sqrt(noise * noise + 0.25);
	noise = clamp(noise, 0.0, 1.0);
	noise = exp(noise * -10.0);
}
#endif

void gbuffersLighting(inout vec4 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, inout vec3 shadow, in vec2 lightmap, 
                      in float NoU, in float NoL, in float NoE,
                      in float subsurface, in float smoothness, in float emission, in float parallaxShadow) {
    //Variables
    float originalNoL = NoL;
    float lViewPos = length(viewPos.xz);
    float ao = color.a * color.a;
    vec3 worldNormal = normalize(ToWorld(normal * 100000000.0));

    //Vanilla Directional Lighting
    float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
          vanillaDiffuse *= vanillaDiffuse;

    #ifdef OVERWORLD
    vanillaDiffuse = mix(1.0, vanillaDiffuse, eBS);
    #endif

    //Block Lighting
    float blockLightMap = pow6(lightmap.x * lightmap.x) * 3.0 + max(lightmap.x - 0.05, 0.0);
          blockLightMap *= blockLightMap * 0.5;

    vec3 blockLighting = blockLightCol * blockLightMap * (1.0 - min(emission, 1.0));

    //Floodfill lighting
    #if !defined GBUFFERS_BASIC && !defined GBUFFERS_WATER && !defined GBUFFERS_TEXTURED && defined IS_IRIS
    vec3 voxelPos = ToVoxel(worldPos);

    float floodfillFade = maxOf(abs(worldPos) / (voxelVolumeSize * 0.5));
          floodfillFade = clamp(floodfillFade, 0.0, 1.0);

    vec3 voxelLighting = vec3(0.0);

    if (isInsideVoxelVolume(voxelPos)) {
        vec3 voxelSamplePos = voxelPos + worldNormal;
             voxelSamplePos /= voxelVolumeSize;
             voxelSamplePos = clamp(voxelSamplePos, 0.0, 1.0);

        vec3 lighting = texture3D(floodfillSampler, voxelSamplePos).rgb;
        voxelLighting = pow(lighting, vec3(1.0 / FLOODFILL_RADIUS));
        voxelLighting *= 0.5 + 0.5 * length(voxelLighting);

        #ifdef GBUFFERS_ENTITIES
        voxelLighting += pow16(lightmap.x) * blockLightCol;
        #endif

        float mixFactor = 1.0 - floodfillFade * floodfillFade;

        blockLighting = mix(blockLighting, voxelLighting * FLOODFILL_BRIGHTNESS, mixFactor * 0.95);
    }
    #endif

    //Dynamic Hand Lighting
    #ifdef DYNAMIC_HANDLIGHT
    getHandLightColor(blockLighting, normal, worldPos + relativeEyePosition);
    #endif

    #ifdef OVERWORLD
    blockLighting *= 1.0 - pow4(lightmap.y) * timeBrightness * 0.75;
    #endif

    //Shadow Calculations
    //Some code made by Emin and gri573
    float shadow0 = 0.0;

    float shadowLightingFade = maxOf(abs(worldPos) / (vec3(shadowDistance, shadowDistance + 128.0, shadowDistance)));
          shadowLightingFade = clamp(shadowLightingFade, 0.0, 1.0);
          shadowLightingFade = 1.0 - shadowLightingFade * shadowLightingFade;

    //Subsurface scattering
    float scattering = 0.0;
    
    #if defined OVERWORLD && defined GBUFFERS_TERRAIN
    if (subsurface > 0.0 && lightmap.y > 0.0) {
        float VoL = clamp(dot(normalize(viewPos), lightVec), 0.0, 1.0);
        scattering = pow8(VoL) * shadowFade * (1.0 - wetness * 0.5);
        if (subsurface > 0.49 && subsurface < 0.51) { //Leaves
            NoL += 0.5 * shadowLightingFade * (0.75 + scattering * 0.75);
        } else if (subsurface > 0.39 && subsurface < 0.41) {
            NoL += 0.1;
        } else if (subsurface > 0.09 && subsurface < 0.11) {
            NoL += 0.25;
        } else {
            NoL += shadowLightingFade * (0.35 + scattering);
        }
    }
    #endif

    if (NoL > 0.0001 && shadowLightingFade > 0.0) {
        vec3 worldPosM = worldPos;

        #ifndef GBUFFERS_TEXTURED
            vec3 bias = worldNormal * min(0.1 + length(worldPos) / 250.0, 0.75);
            vec3 edgeFactor = 0.25 * (0.5 - fract(worldPosM + cameraPosition + worldNormal * 0.01));
            worldPosM += (1.0 - pow2(pow2(max(color.a, lightmap.y * lightmap.y)))) * edgeFactor;
            worldPosM += bias;
        #else
            vec3 centerWorldPos = floor(worldPosM + cameraPosition) - cameraPosition + 0.5;
            worldPosM = mix(centerWorldPos, worldPosM + vec3(0.0, 0.02, 0.0), lightmap.y);
        #endif

        vec3 shadowPos = ToShadow(worldPosM);

        float viewDistance = 1.0 - clamp(lViewPos * 0.01, 0.0, 1.0);

        float offset = 0.001;
        #if defined GBUFFERS_TERRAIN
              offset *= 1.0 + viewDistance * (float(subsurface > 0.3) * 3.0 + float(subsurface == 0.5) * 2.0);
              offset *= 1.0 - viewDistance * float(subsurface == 0.3) * 0.4;
        #endif

        #ifndef GBUFFERS_TERRAIN
        float subsurface = 0.0;
        #endif

        shadow = computeShadow(shadowPos, offset, lightmap.y, subsurface, viewDistance, shadow0);
    }

    #ifdef VC_SHADOWS
    //Cloud parameters
    float speed = VC_SPEED;
    float amount = VC_AMOUNT;
    float frequency = VC_FREQUENCY;
    float density = VC_DENSITY;
    float height = VC_HEIGHT;

    getDynamicWeather(speed, amount, frequency, density, height);

    vec2 wind = vec2(frameTimeCounter * speed * 0.005, sin(frameTimeCounter * speed * 0.1) * 0.01) * speed * 0.1;
    vec3 worldSunVec = mat3(gbufferModelViewInverse) * lightVec;
    vec3 cloudShadowPos = worldPos + cameraPosition + (worldSunVec / max(abs(worldSunVec.y), 0.0)) * max((VC_HEIGHT + VC_THICKNESS + 25.0) - worldPos.y - cameraPosition.y, 0.0);

    float noise = 0.0;
    getCloudShadow(cloudShadowPos.xz, wind, amount, frequency, density, noise);

    shadow = mix(vec3(0.0), shadow, vec3(noise) * VC_OPACITY);
    #endif

    vec3 fakeShadow = getFakeShadow(lightmap.y);
    if (subsurface > 0.0) fakeShadow *= originalNoL;

    shadow = mix(fakeShadow, shadow, vec3(shadowLightingFade));

    #if defined PBR && defined GBUFFERS_TERRAIN
    shadow *= parallaxShadow;
    #endif

    shadow *= clamp(NoL * 1.01 - 0.01, 0.0, 1.0);

    //Scene Lighting
    #ifdef OVERWORLD
    float rainFactor = 1.0 - wetness * 0.75;
    vec3 sceneLighting = mix(ambientCol * pow4(lightmap.y), lightCol, shadow * rainFactor * shadowFade);
         sceneLighting *= 1.0 + scattering * shadow;

    #elif defined END
    vec3 sceneLighting = mix(endAmbientCol, endLightCol, shadow) * 0.25;
    #elif defined NETHER
    vec3 sceneLighting = pow(netherColSqrt, vec3(0.75)) * 0.03;
    #endif

    //Specular Highlight
    vec3 specularHighlight = vec3(0.0);

    if (emission < 0.01) {
        #if (defined GBUFFERS_TERRAIN || defined GBUFFERS_ENTITIES || defined GBUFFERS_BLOCK) && !defined NETHER
        vec3 baseReflectance = vec3(0.1);

        float smoothnessF = 0.1 + length(albedo.rgb) * 0.2 + originalNoL * 0.2;
              smoothnessF = mix(smoothnessF, 0.95, smoothness);
              smoothnessF *= float(scattering < 0.001);

        #ifdef OVERWORLD
        specularHighlight = getSpecularHighlight(normal, viewPos, smoothnessF, baseReflectance, lightCol, shadow * vanillaDiffuse, color.a);
        #else
        specularHighlight = getSpecularHighlight(normal, viewPos, smoothnessF, baseReflectance, endLightCol, shadow * vanillaDiffuse, color.a);
        #endif

        specularHighlight = clamp(specularHighlight, vec3(0.0), vec3(3.0));
        #endif
    }

    //Minimal Lighting
    #if defined OVERWORLD || defined END
    sceneLighting += minLightCol * (1.0 - lightmap.y);
    #endif

    //Night vision
    sceneLighting += nightVision * vec3(0.1, 0.15, 0.1);

    //Aurora Lighting
    vec3 auroraLighting = vec3(0.0);

    #if defined AURORA && defined AURORA_LIGHTING_INFLUENCE && !defined GBUFFERS_TEXTURED && !defined GBUFFERS_WATER && !defined GBUFFERS_BASIC
	float visibilityMultiplier = pow8(1.0 - sunVisibility) * (1.0 - wetness) * pow4(lightmap.y) * AURORA_BRIGHTNESS;
	float auroraVisibility = 0.0;

	#ifdef AURORA_FULL_MOON_VISIBILITY
	auroraVisibility = mix(auroraVisibility, 1.0, float(moonPhase == 0));
	#endif

	#ifdef AURORA_COLD_BIOME_VISIBILITY
	auroraVisibility = mix(auroraVisibility, 1.0, isSnowy);
	#endif

    #ifdef AURORA_ALWAYS_VISIBLE
    auroraVisibility = 1.0;
    #endif

	auroraVisibility *= visibilityMultiplier;
    auroraLighting = vec3(0.4, 2.5, 0.9) * 0.005 * auroraVisibility * (0.5 + NoU * 0.5);
    #endif

    //Vanilla AO
    #ifdef VANILLA_AO
    float aoMixer = (1.0 - ao) * (1.0 - pow6(lightmap.x));
    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao * ao, aoMixer * AO_STRENGTH);
    #endif

    //RSM GI//
    vec3 gi = vec3(0.0);

    #if defined GI && defined GBUFFERS_TERRAIN
    vec2 prevScreenPos = Reprojection(screenPos);
    gi = texture2D(gaux1, prevScreenPos).rgb;
    gi = pow4(gi) * 32.0 * lightmap.y * sunVisibility * shadowFade;

    #if defined OVERWORLD
    gi *= lightCol;
    #elif defined NETHER
    gi *= endLightCol;
    #endif
    #endif

    albedo.rgb = pow(albedo.rgb, vec3(2.2));
    albedo.rgb *= (sceneLighting + auroraLighting) * vanillaDiffuse + blockLighting + gi + emission;
    albedo.rgb += specularHighlight;
    albedo.rgb = pow(albedo.rgb, vec3(1.0 / 2.2));
}