vec3 lightMorning    = vec3(LIGHT_MR,   LIGHT_MG,   LIGHT_MB)   * LIGHT_MI / 255.0;
vec3 lightDay        = vec3(LIGHT_DR,   LIGHT_DG,   LIGHT_DB)   * LIGHT_DI / 255.0;
vec3 lightEvening    = vec3(LIGHT_ER,   LIGHT_EG,   LIGHT_EB)   * LIGHT_EI / 255.0;
vec3 lightNight      = vec3(LIGHT_NR,   LIGHT_NG,   LIGHT_NB)   * LIGHT_NI / 255.0;

vec3 ambientMorning  = vec3(AMBIENT_MR, AMBIENT_MG, AMBIENT_MB) * AMBIENT_MI / 255.0;
vec3 ambientDay      = vec3(AMBIENT_DR, AMBIENT_DG, AMBIENT_DB) * AMBIENT_DI / 255.0;
vec3 ambientEvening  = vec3(AMBIENT_ER, AMBIENT_EG, AMBIENT_EB) * AMBIENT_EI / 255.0;
vec3 ambientNight    = vec3(AMBIENT_NR, AMBIENT_NG, AMBIENT_NB) * AMBIENT_NI / 255.0;

#ifdef FOG_PERBIOME
uniform float isDesert, isMesa, isCold, isSwamp, isMushroom, isSavanna, isJungle, isTaiga;

vec3 weatherRain     = vec3(WEATHER_RR, WEATHER_RG, WEATHER_RB) / 255.0 * WEATHER_RI;
vec3 weatherCold     = vec3(WEATHER_CR, WEATHER_CG, WEATHER_CB) / 255.0 * WEATHER_CI;
vec3 weatherDesert   = vec3(WEATHER_DR, WEATHER_DG, WEATHER_DB) / 255.0 * WEATHER_DI;
vec3 weatherBadlands = vec3(WEATHER_BR, WEATHER_BG, WEATHER_BB) / 255.0 * WEATHER_BI;
vec3 weatherSwamp    = vec3(WEATHER_SR, WEATHER_SG, WEATHER_SB) / 255.0 * WEATHER_SI;
vec3 weatherMushroom = vec3(WEATHER_MR, WEATHER_MG, WEATHER_MB) / 255.0 * WEATHER_MI;
vec3 weatherSavanna  = vec3(WEATHER_VR, WEATHER_VG, WEATHER_VB) / 255.0 * WEATHER_VI;
vec3 weatherTaiga    = vec3(WEATHER_TR, WEATHER_TG, WEATHER_TB) / 255.0 * WEATHER_TI;
vec3 weatherJungle   = vec3(WEATHER_JR, WEATHER_JG, WEATHER_JB) / 255.0 * WEATHER_JI;

float weatherWeight = isCold + isDesert + isMesa + isSwamp + isMushroom + isSavanna + isJungle + isTaiga;

vec3 getBiomeColor(vec3 inCol) {
	return mix(
		inCol,
		(
			weatherCold  * isCold  + weatherDesert   * isDesert   + weatherBadlands * isMesa    +
			weatherSwamp * isSwamp + weatherMushroom * isMushroom + weatherSavanna  * isSavanna +
			weatherJungle * isJungle + weatherTaiga * isTaiga
		) / max(weatherWeight, 0.0001),
		weatherWeight * 0.5
	);
}

vec3 weatherCol = getBiomeColor(weatherRain);

#else
vec3 weatherCol = vec3(WEATHER_RR, WEATHER_RG, WEATHER_RB) / 255.0 * WEATHER_RI;
#endif

float mefade = 1.0 - clamp(abs(timeAngle - 0.5) * 8.0 - 1.5, 0.0, 1.0);
float dfade = 1.0 - pow2(1.0 - timeBrightness);

vec3 lightSun = mix(mix(lightMorning, lightEvening, mefade), lightDay, dfade);
vec3 ambientSun = mix(mix(ambientMorning, ambientEvening, mefade), ambientDay, dfade);

vec3 lightColRaw = mix(lightNight, lightSun, sunVisibility);
vec3 lightColSqrt = mix(lightColRaw, dot(lightColRaw, vec3(0.299, 0.587, 0.114)) * weatherCol.rgb, rainStrength);
vec3 lightCol = lightColSqrt * lightColSqrt;

vec3 ambientColRaw = mix(ambientNight, ambientSun, sunVisibility);
vec3 ambientColSqrt = mix(ambientColRaw, dot(ambientColRaw, vec3(0.299, 0.587, 0.114)) * weatherCol.rgb, rainStrength);
vec3 ambientCol = ambientColSqrt * ambientColSqrt;