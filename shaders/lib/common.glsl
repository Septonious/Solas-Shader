////////////// S H A D E R   S E T T I N G S //////////////

//Shadows//
const int shadowMapResolution = 1024; //[512 1024 1536 2048 3072]
const float shadowDistance = 192.0; //[128.0 192.0 256.0 320.0 384.0 448.0 512.0]
const float sunPathRotation = -40.0; //[-85.0 -80.0 -75.0 -70.0 -65.0 -60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0 65.0 70.0 75.0 80.0 85.0]
const float shadowMapBias = 1.0 - 25.6 / shadowDistance;

#define SHADOW_COLOR
#define VPS
#define VPS_BLUR_STRENGTH 0.50 //[0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80]
//#define ENTITY_SHADOWS

//Ambient Occlusion//
#define VANILLA_AO
#define AO
#define AO_RADIUS 0.7 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define AO_STRENGTH 0.5 //[0.5 0.6 0.7 0.8 0.9 1.0]

//Colored Lighting//
#define COLORED_LIGHTING
#define COLORED_LIGHTING_RADIUS 1.25 //[1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define COLORED_LIGHTING_MIX 0.8 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

//Global Illumination//
//#define GLOBAL_ILLUMINATION
#define GLOBAL_ILLUMINATION_STRENGTH 1.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define GLOBAL_ILLUMINATION_RADIUS 4.00 //[1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]

//Integrated PBR//
#define INTEGRATED_NORMAL_MAPPING
#define NORMAL_STRENGTH 12.0 //[1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0]
#define NORMAL_RESOLUTION 128.0 //[64.0 96.0 128.0 160.0 192.0]
#define NORMAL_THRESHOLD 0.15 //[0.05 0.10 0.15 0.20 0.25]
#define INTEGRATED_EMISSION
//#define PLAYER_BRIGHT_PARTS_HIGHLIGHT
#define EMISSIVE_FLOWERS
#define EMISSIVE_ORES
#define EMISSIVE_CORALS
//#define EMISSIVE_POWDER_SNOW
#define EMISSIVE_DEBRIS
//#define ENTITY_HIGHLIGHT
//#define EMISSIVE_CONCRETE
#define EMISSION_STRENGTH 2.5 //[1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]
#define RAIN_PUDDLES
#define INTEGRATED_SPECULAR
#define SPECULAR_STRENGTH 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define WATER_SPECULAR_STRENGTH 0.9 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

//Depth of Field//
//#define DOF
#define DOF_STRENGTH 3.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]

//Distant Blur//
#define DISTANT_BLUR
#define DISTANT_BLUR_STRENGTH 2.0 //[1.0 1.5 2.0 2.5 3.0 3.5 4.0]
#define DISTANT_BLUR_RANGE 4 //[1 2 3 4 5 6 7 8]

//Motion Blur//
//#define MOTION_BLUR
#define MOTION_BLUR_STRENGTH 0.50 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]

//Bloom//
#define BLOOM
#define BLOOM_STRENGTH 2.50 //[1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00 4.25 4.50 4.75 5.00 5.25 5.50 5.75 6.00]
#define BLOOM_CONTRAST 1 //[-4 -3 -2 -1 0 1 2 3 4]
#define BLOOM_TILE_SIZE 0.0 //[0.0 0.5 1.0 1.5 2.0]

//Atmosphere//
#define RAINBOW
#define MILKY_WAY
#define MILKY_WAY_BRIGHTNESS 3.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define END_NEBULA
#define END_NEBULA_BRIGHTNESS 1.50 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define END_VORTEX
#define END_VORTEX_ARMS 4.0 //[4.0 5.0 6.0 7.0 8.0]
#define END_VORTEX_WHIRL 20.0 //[16.0 18.0 20.0 22.0 24.0 26.0 28.0 30.0 32.0]
#define END_STARS
#define STARS
#define AURORA
#define AURORA_BRIGHTNESS 0.4 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define AURORA_FULL_MOON_VISIBILITY
#define AURORA_COLD_BIOME_VISIBILITY

//Fog//
#define DISTANT_FADE
#define DISTANT_FADE_STYLE 0 //[0 1]
#define FOG_DENSITY 2.00 //[0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define FOG_HEIGHT 100.0 //[50.0 60.0 70.0 80.0 90.0 100.0 110.0 120.0 130.0 140.0 150.0 170.0 180.0 190.0 200.0]

//Volumetric Nether & End Fog//
#define VF_NETHER_END
#define VF_NETHER_STRENGTH 0.50 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]
#define VF_NETHER_SAMPLES 8 //[6 7 8 9 10 11 12]
#define VF_NETHER_FREQUENCY 3.50 //[2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define VF_NETHER_SPEED 6.00 //[1.00 1.50 2.00 2.50 3.00 3.50 4.00 4.50 5.00 5.50 6.00 6.50 7.00 7.50 8.00]
#define VF_NETHER_REFRACTION
#define VF_NETHER_REFRACTION_STRENGTH 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]

#define VF_END_HEIGHT 0.0 //[0.0 10.0 20.0 30.0 40.0 50.0 60.0 70.0]
#define VF_END_AMOUNT 7.5 //[7.5 8.0 8.5 9.0 9.5 10.0]
#define VF_END_THICKNESS 12.0 //[4.0 6.0 8.0 10.0 12.0 14.0 16.0 18.0 20.0 22.0 24.0]

//Volumetric Light
#define VL
#define VL_CLOUDY_NOISE
#define VL_STRENGTH 2.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define VL_SAMPLES 8 //[6 7 8 9 10 11 12]

//Volumetric Clouds
#define VC
//#define BLOCKY_CLOUDS
#define VC_DYNAMIC_WEATHER
#define VC_DENSITY 8.0 //[4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define VC_AMOUNT 11.5 //[13.0 12.5 12.0 11.5 11.0 10.5 10.0]
#define VC_HEIGHT 150.0 //[100.0 110.0 120.0 130.0 140.0 150.0 160.0 170.0 180.0 190.0 200.0]
#define VC_THICKNESS 6.0 //[4.0 5.0 6.0 7.0 8.0]
#define VC_DETAIL 1.6 //[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define VC_SPEED 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00 3.50 4.00]
#define VC_OPACITY 0.7 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define VC_DISTANCE 400.0 //[300.0 400.0 500.0 600.0 700.0 800.0 900.0 1000.0]

//Water//
//#define VANILLA_WATER
#define WATER_NORMALS 1 //[0 1 2]
#define WATER_NORMAL_BUMP 0.4 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define WATER_NORMAL_OFFSET 0.5 //[0.2 0.3 0.4 0.5 0.6 0.7 0.8]
#define WATER_NORMAL_DETAIL 0.40 //[0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50]
#define WATER_NORMAL_SPEED 1.50 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00 3.50 4.00]
#define WATER_CAUSTICS
#define WATER_CAUSTICS_STRENGTH 3.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define WATER_FOG
#define WATER_FOG_DENSITY 0.6 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define REFRACTION
#define REFRACTION_STRENGTH 0.7 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

//Waving Stuff//
#define WAVING_WATER
#define WAVING_BLOCKS
#define WAVING_PLANTS
#define WAVING_LEAVES
#define WAVING_AMPLITUDE 1.75 //[1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define WAVING_SPEED 0.9 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

//Post Processing//
#define FXAA
#define TAA
//#define CHROMATIC_ABERRATION
#define CHROMATIC_ABERRATION_STRENGTH 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]
#define NETHER_CHROMATIC_ABERRATION
#define SHARPENING

#define TONEMAP_LOWER_CURVE 1.4 //[0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define TONEMAP_UPPER_CURVE 1.0 //[0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define TONEMAP_WHITE_CURVE 1.2  //[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5]

#define EXPOSURE 0.00 //[-1.00 -0.90 -0.80 -0.70 -0.60 -0.50 -0.40 -0.30 -0.20 -0.10 0.00 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.00]
#define SATURATION 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define VIBRANCE 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

//Colors//
#define LIGHTTEMP_SS 2750 //[2500 2750 3000 3250 3500]
#define LIGHTTEMP_ME 3250 //[3500 3750 4000 4250 4500]
#define LIGHTTEMP_D 6000 //[6500 6750 7000 7250 7500]
#define LIGHTTEMP_N 10750 //[10000 10250 10500 10750 11000]

#define LIGHTINTENSITY_SS 1.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define LIGHTINTENSITY_ME 1.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define LIGHTINTENSITY_D 1.2 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define LIGHTINTENSITY_N 0.4 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define WATER_R 50 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define WATER_G 210 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define WATER_B 255 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define WATER_I 0.75 //[0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define WATER_A 0.85 //[0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75]

#define WEATHER_RR 175 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define WEATHER_RG 185 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define WEATHER_RB 255 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define WEATHER_RI 0.60 //[0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00]

#define SKY_R 160 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define SKY_G 175 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define SKY_B 255 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define SKY_I 0.75 //[0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00]

#define LIGHT_END_R 145 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define LIGHT_END_G 125 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define LIGHT_END_B 255 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define LIGHT_END_I 1.00 //[0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00]

#define AMBIENT_END_R 195 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define AMBIENT_END_G 145 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define AMBIENT_END_B 255 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define AMBIENT_END_I 0.50 //[0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00]

#define MINLIGHT_R 100 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define MINLIGHT_G 110 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define MINLIGHT_B 120 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define MINLIGHT_I 0.85 //[0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

#define BLOCKLIGHT_R 245 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define BLOCKLIGHT_G 215 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define BLOCKLIGHT_B 185 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define BLOCKLIGHT_I 1.00 //[0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00]

#define DYNAMIC_HANDLIGHT

////////////// F U N C T I O N S //////////////

//POWs//
float pow2(float x) {return x*x;}
float pow3(float x) {return x*x*x;}
float pow4(float x) {return x*x*x*x;}
float pow5(float x) {return x*x*x*x*x;}
float pow6(float x) {return x*x*x*x*x*x;}
float pow7(float x) {return x*x*x*x*x*x*x;}
float pow8(float x) {return x*x*x*x*x*x*x*x;}
float pow9(float x) {return x*x*x*x*x*x*x*x*x;}
float pow10(float x) {return x*x*x*x*x*x*x*x*x*x;}
float pow11(float x) {return x*x*x*x*x*x*x*x*x*x*x;}
float pow12(float x) {return x*x*x*x*x*x*x*x*x*x*x*x;}
float pow13(float x) {return x*x*x*x*x*x*x*x*x*x*x*x*x;}
float pow14(float x) {return x*x*x*x*x*x*x*x*x*x*x*x*x*x;}
float pow15(float x) {return x*x*x*x*x*x*x*x*x*x*x*x*x*x*x;}
float pow16(float x) {return x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x;}
float pow17(float x) {return x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x;}
float pow18(float x) {return x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x;}
float pow19(float x) {return x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x;}
float pow20(float x) {return x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x;}
float pow24(float x) {return x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x;}
float pow32(float x) {return x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x;}

vec2 pow2(vec2 x) {return x*x;}
vec2 pow3(vec2 x) {return x*x*x;}
vec2 pow4(vec2 x) {return x*x*x*x;}
vec2 pow5(vec2 x) {return x*x*x*x*x;}
vec2 pow6(vec2 x) {return x*x*x*x*x*x;}
vec2 pow7(vec2 x) {return x*x*x*x*x*x*x;}
vec2 pow8(vec2 x) {return x*x*x*x*x*x*x*x;}

vec3 pow2(vec3 x) {return x*x;}
vec3 pow3(vec3 x) {return x*x*x;}
vec3 pow4(vec3 x) {return x*x*x*x;}
vec3 pow5(vec3 x) {return x*x*x*x*x;}
vec3 pow6(vec3 x) {return x*x*x*x*x*x;}
vec3 pow7(vec3 x) {return x*x*x*x*x*x*x;}
vec3 pow8(vec3 x) {return x*x*x*x*x*x*x*x;}
vec3 pow16(vec3 x) {return x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x;}

vec4 pow4(vec4 x) {return x*x*x*x;}

////////////// V A R I A B L E S //////////////

#define SOLAS_BY_SEPTONIOUS 0 //[0]

//Sky Color//
const vec3 skyColSqrt = vec3(SKY_R, SKY_G, SKY_B) * SKY_I / 255.0;

//Blocklight Color//
const vec3 blockLightColSqrt = vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B) * BLOCKLIGHT_I / 255.0;
const vec3 blockLightCol = blockLightColSqrt * blockLightColSqrt;

//Minlight Color//
const vec3 minLightColSqrt = vec3(MINLIGHT_R, MINLIGHT_G, MINLIGHT_B) * MINLIGHT_I / 255.0;
const vec3 minLightCol = minLightColSqrt * minLightColSqrt * 0.1;
const vec3 caveMinLightCol = skyColSqrt * 0.25;

//End Color//
const vec3 endLightColSqrt = vec3(LIGHT_END_R, LIGHT_END_G, LIGHT_END_B) / 255.0 * LIGHT_END_I;
const vec3 endLightCol = endLightColSqrt * endLightColSqrt;

const vec3 endAmbientColSqrt = vec3(AMBIENT_END_R, AMBIENT_END_G, AMBIENT_END_B) / 255.0 * AMBIENT_END_I;
const vec3 endAmbientCol = endAmbientColSqrt * endAmbientColSqrt;

//Water Color//
const vec3 waterColorSqrt = vec3(WATER_R, WATER_G, WATER_B) / 255.0 * WATER_I;
const vec3 waterColor = waterColorSqrt * waterColorSqrt;

//Water Fog Range//
const float waterFogRange = 64.0 / WATER_FOG_DENSITY;

//Weather Color//
const vec3 weatherCol = vec3(WEATHER_RR, WEATHER_RG, WEATHER_RB) / 255.0 * WEATHER_RI;

//Mathematical Constants//
const float PI = 3.1415926;
const float TAU = 6.2831853;

////////////// S H E N A N I G A N S //////////////

#ifndef END
#undef END_VORTEX
#undef END_NEBULA
#undef END_STARS
#endif

#ifndef OVERWORLD
#undef AURORA
#undef STARS
#undef MILKY_WAY
#undef RAINBOW
#undef VC
#undef VL
#undef WAVING_BLOCKS
#undef GLOBAL_ILLUMINATION
#undef VF_NETHER_REFRACTION
#endif

#ifdef OVERWORLD
#undef VF_NETHER_END
#endif

#ifdef NETHER
#undef WATER_FOG
#ifdef NETHER_CHROMATIC_ABERRATION
#ifndef CHROMATIC_ABERRATION
#define CHROMATIC_ABERRATION
#endif
#endif
#endif

#ifndef INTEGRATED_SPECULAR
#undef RAIN_PUDDLES
#endif

#ifndef VC
#undef BLOCKY_CLOUDS
#endif

#ifdef ENTITY_SHADOWS
#endif

#ifdef EMISSIVE_FLOWERS
#endif

#ifdef COLORED_LIGHTING
#endif

#ifdef VPS
#endif

#ifdef AO
#endif

#if defined VPS && !defined GBUFFERS_TERRAIN
#undef VPS
#endif

#if defined GBUFFERS_TEXTURED || defined GBUFFERS_HAND || defined GBUFFERS_BASIC || defined GBUFFERS_WATER
#undef COLORED_LIGHTING
#undef GLOBAL_ILLUMINATION
#endif

#ifdef DOF
#endif