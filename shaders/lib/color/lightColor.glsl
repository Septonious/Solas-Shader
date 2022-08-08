const vec3 lightEarlyMorning  = vec3(LIGHT_EMR, LIGHT_EMG, LIGHT_EMB) * LIGHT_EMI / 255.0;
const vec3 lightMorning       = vec3(LIGHT_MR, LIGHT_MG, LIGHT_MB) * LIGHT_MI / 255.0;
const vec3 lightDay           = vec3(LIGHT_DR, LIGHT_DG, LIGHT_DB) * LIGHT_DI / 255.0;
const vec3 lightEvening       = vec3(LIGHT_ER, LIGHT_EG, LIGHT_EB) * LIGHT_EI / 255.0;
const vec3 lightLateEvening   = vec3(LIGHT_LER, LIGHT_LEG, LIGHT_LEB) * LIGHT_LEI / 255.0;
const vec3 lightNight         = vec3(LIGHT_NR, LIGHT_NG, LIGHT_NB) * LIGHT_NI / 255.0;

const vec3 ambientEarlyMorning  = vec3(AMBIENT_EMR, AMBIENT_EMG, AMBIENT_EMB) * AMBIENT_EMI / 255.0;
const vec3 ambientMorning       = vec3(AMBIENT_MR, AMBIENT_MG, AMBIENT_MB) * AMBIENT_MI / 255.0;
const vec3 ambientDay           = vec3(AMBIENT_DR, AMBIENT_DG, AMBIENT_DB) * AMBIENT_DI / 255.0;
const vec3 ambientEvening       = vec3(AMBIENT_ER, AMBIENT_EG, AMBIENT_EB) * AMBIENT_EI / 255.0;
const vec3 ambientLateEvening   = vec3(AMBIENT_LER, AMBIENT_LEG, AMBIENT_LEB) * AMBIENT_LEI / 255.0;
const vec3 ambientNight         = vec3(AMBIENT_NR, AMBIENT_NG, AMBIENT_NB) * AMBIENT_NI / 255.0;

float mefade = 1.0 - clamp(abs(timeAngle - 0.5) * 8.0 - 1.5, 0.0, 1.0);
float dfade = sqrt(timeBrightness);
float sqrtdfade = sqrt(dfade);

vec3 morningLightColor = mix(lightEarlyMorning, lightMorning, sqrtdfade);
vec3 eveningLightColor = mix(lightLateEvening, lightEvening, sqrtdfade);
vec3 morningAmbientColor = mix(ambientEarlyMorning, ambientMorning, sqrtdfade);
vec3 eveningAmbientColor = mix(ambientLateEvening, ambientEvening, sqrtdfade);

vec3 lightSun = mix(mix(morningLightColor, eveningLightColor, mefade), lightDay, dfade);
vec3 ambientSun = mix(mix(morningAmbientColor, eveningAmbientColor, mefade), ambientDay, dfade);

vec3 lightColRaw = mix(lightNight, lightSun, sunVisibility * sunVisibility);
vec3 lightColSqrt = mix(lightColRaw, dot(lightColRaw, vec3(0.299, 0.587, 0.114)) * weatherCol, rainStrength);
vec3 lightCol = lightColSqrt * lightColSqrt;

vec3 ambientColRaw = mix(ambientNight, ambientSun, sunVisibility * sunVisibility);
vec3 ambientColSqrt = mix(ambientColRaw, dot(ambientColRaw, vec3(0.299, 0.587, 0.114)) * weatherCol, rainStrength);
vec3 ambientCol = ambientColSqrt * ambientColSqrt;