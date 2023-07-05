float timeBrightnessSqrt = sqrt(timeBrightness);

float temperatureSun = mix(mix(LIGHTTEMP_SS, LIGHTTEMP_ME, timeBrightnessSqrt), LIGHTTEMP_D, timeBrightness) * 0.01;
float temperatureNight = LIGHTTEMP_N * 0.01;

vec3 colorSun = vec3(1.0, clamp(0.390081578 * log(temperatureSun) - 0.631841443, 0.0, 1.0), clamp(0.543206789 * log(temperatureSun - 10.0) - 1.196254089, 0.0, 1.0));
vec3 colorNight = vec3(clamp(1.292936186 * pow(temperatureNight - 60.0, -0.133204759), 0.0, 1.0), clamp(1.129890860 * pow(temperatureNight - 60.0, -0.075514849), 0.0, 1.0), 1.0);

vec3 lightSun = mix(pow((colorSun + 0.055) / 1.055, vec3(2.4)), colorSun / 12.92, step(colorSun, vec3(0.04045)))
              * mix(mix(LIGHTINTENSITY_SS, LIGHTINTENSITY_ME, timeBrightnessSqrt), LIGHTINTENSITY_D, timeBrightness);
vec3 lightNight = mix(pow((colorNight + 0.055) / 1.055, vec3(2.4)), colorNight / 12.92, step(colorNight, vec3(0.04045)))
              * LIGHTINTENSITY_N;

vec3 lightColRaw = mix(lightNight, lightSun, sunVisibility * sunVisibility);
vec3 lightColSqrt = mix(lightColRaw, dot(lightColRaw, vec3(0.299, 0.587, 0.114)) * weatherCol, rainStrength);
vec3 lightCol = lightColSqrt * lightColSqrt;

vec3 ambientColRaw = mix(lightNight, mix(lightColRaw, vec3(0.25, 0.55, 1.0), 0.65), sunVisibility * sunVisibility) * 0.5;
vec3 ambientColSqrt = mix(ambientColRaw, dot(ambientColRaw, vec3(0.299, 0.587, 0.114)) * weatherCol, rainStrength);
vec3 ambientCol = ambientColSqrt * ambientColSqrt;