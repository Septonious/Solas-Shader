#if defined OVERWORLD
float timeBrightnessSqrt = sqrt(timeBrightness);
float mefade = 1.0 - clamp(abs(timeAngle - 0.5) * 8.0 - 1.5, 0.0, 1.0);
float dfade = 1.0 - pow(1.0 - timeBrightness, 1.5);

vec3 lightSun = fmix(fmix(fmix(lightSunrise, lightMorning, timeBrightnessSqrt), fmix(lightEvening, lightSunset, 1.0 - timeBrightnessSqrt), mefade), lightDay, dfade);
vec3 ambientSun = fmix(fmix(fmix(ambientSunrise, ambientMorning, timeBrightnessSqrt), fmix(ambientEvening, ambientSunset, 1.0 - timeBrightnessSqrt), mefade), ambientDay, dfade);

vec3 lightColRaw = fmix(lightNight, lightSun, sunVisibility);
vec3 lightColSqrt = fmix(lightColRaw, lightColRaw * weatherCol, wetness * 0.75);
vec3 lightCol = lightColSqrt * lightColSqrt;

vec3 ambientColRaw = fmix(ambientNight, ambientSun, sunVisibility);
vec3 ambientColSqrt = fmix(ambientColRaw, ambientColRaw * weatherCol, wetness * 0.75);
vec3 ambientCol = ambientColSqrt * ambientColSqrt;

//Per-biome weather
//Every biome specified here has a corresponding uniform in the /shaders/shaders.properties file
#ifndef VOXY_OPAQUE
uniform float isSnowy, isDesert, isCherryGrove, isSwamp, isMushroom, isJungle, isLushCaves, isDeepDark;
#endif

//Color for each biome. Format: vec3(biome_color_red, biome_color_green, biome_color_blue) * isBiome
vec3 biomeColor = vec3(1.105, 0.805, 0.615) * (1.0 + timeBrightness * 0.5) * isDesert +
                  vec3(1.095, 0.925, 1.025) * isCherryGrove +
                  vec3(1.025, 1.285, 0.785) * isSwamp +
                  vec3(1.115, 0.745, 0.975) * isMushroom +
                  vec3(0.955, 1.085, 0.895) * isJungle;

vec3 caveBiomeColor = vec3(0.125, 0.145, 0.035) * isLushCaves + vec3(0.025, 0.095, 0.135) * isDeepDark;

//This variable toggles per-biome weather when a player enters a specific biome
float isSpecificBiome = isDesert + isCherryGrove + isSwamp + isMushroom + isJungle;
float isCaveBiome = isLushCaves + isDeepDark;
#elif defined NETHER
vec3 netherColSqrt = pow(normalize(fogColor + 0.00000001), vec3(0.125));
#endif