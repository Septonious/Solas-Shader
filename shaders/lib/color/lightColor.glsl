#ifdef OVERWORLD
float timeBrightnessSqrt = sqrt(timeBrightness);
float mefade = 1.0 - clamp(abs(timeAngle - 0.5) * 8.0 - 1.5, 0.0, 1.0);

float temperatureSun = mix(mix(LIGHTTEMP_SS, LIGHTTEMP_ME, timeBrightnessSqrt), LIGHTTEMP_D, timeBrightness * timeBrightness) * 0.01;
float temperatureNight = LIGHTTEMP_N * 0.01;

vec3 colorSun = vec3(1.0, clamp(0.390081578 * log(temperatureSun) - 0.631841443, 0.0, 1.0), clamp(0.543206789 * log(temperatureSun - 10.0) - 1.196254089, 0.0, 1.0));
vec3 colorNight = vec3(clamp(1.292936186 * pow(temperatureNight - 60.0, -0.133204759), 0.0, 1.0), clamp(1.129890860 * pow(temperatureNight - 60.0, -0.075514849), 0.0, 1.0), 1.0);

#ifdef GBUFFERS_TERRAIN
float lightSunIntensity = mix(mix(LIGHTINTENSITY_SS * LIGHTINTENSITY_SS, LIGHTINTENSITY_ME * LIGHTINTENSITY_ME, timeBrightnessSqrt), LIGHTINTENSITY_D * LIGHTINTENSITY_D, timeBrightness);
#else
float lightSunIntensity = mix(mix(LIGHTINTENSITY_SS, LIGHTINTENSITY_ME, timeBrightnessSqrt), LIGHTINTENSITY_D, timeBrightness);
#endif

vec3 lightSun = normalize(mix(pow((colorSun + 0.055) / 1.055, vec3(2.2)), colorSun / 12.92, step(colorSun, vec3(0.04045)))) * lightSunIntensity;
vec3 lightNight = mix(pow((colorNight + 0.055) / 1.055, vec3(2.2)), colorNight / 12.92, step(colorNight, vec3(0.04045))) * LIGHTINTENSITY_N * 0.5;

#ifdef PURPLE_MORNINGS
vec3 lightColRaw = mix(lightNight, mix(vec3(lightSun.r, lightSun.g, lightSun.b * (2.25 - clamp((mefade + timeBrightness) * 6.0, 0.0, 1.25))), normalize(skyColor + 0.0001), 0.1), sunVisibility * sunVisibility);
#else
vec3 lightColRaw = mix(lightNight, mix(lightSun, normalize(skyColor + 0.0001), 0.1), sunVisibility * sunVisibility);
#endif

vec3 lightColSqrt = mix(lightColRaw, dot(lightColRaw, vec3(0.299, 0.587, 0.114)) * weatherCol, wetness * 0.5);
vec3 lightCol = lightColSqrt * lightColSqrt;

float ambientIntensity = mix(AMBIENTINTENSITY_N, mix(AMBIENTINTENSITY_D * 0.65, AMBIENTINTENSITY_D, timeBrightness), sunVisibility * sunVisibility);
vec3 ambientColor = mix(lightNight, mix(lightColRaw, normalize(skyColor + 0.0001), AMBIENTCOL_SKY_INFLUENCE) * normalize(mix(vec3(1.0), skyColor, AMBIENTCOL_SKY_INFLUENCE) + 0.0001), sunVisibility * sunVisibility);
vec3 ambientColRaw = pow(ambientColor, vec3(0.75)) * 0.5 * ambientIntensity;
vec3 ambientColSqrt = mix(ambientColRaw, dot(ambientColRaw, vec3(0.299, 0.587, 0.114)) * weatherCol, wetness * 0.5);
vec3 ambientCol = ambientColSqrt * ambientColSqrt;
#endif