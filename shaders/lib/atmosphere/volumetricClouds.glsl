float amount = VC_AMOUNT * (1.0 + rainStrength * 0.5);
vec3 wind = vec3(frameTimeCounter, 0.0, 0.0);

float getCloudSample(vec3 pos, in float sampleHeight) {
	float noise = getTextureNoise(pos * 0.625 + wind * 0.4) * 1.00;
		  noise+= getTextureNoise(pos * 0.250 + wind * 0.3) * 1.50;
		  noise+= getTextureNoise(pos * 0.125 + wind * 0.2) * 3.00;
		  noise+= getTextureNoise(pos * 0.025 + wind * 0.1) * 9.00;

	return clamp(noise * amount - (10.0 + sampleHeight * 5.0), 0.0, 1.0);
}

const float distanceThreshold = VC_SAMPLES * VC_DISTANCE * 2.0;

vec4 getVolumetricCloud(vec3 viewPos, vec2 coord, float depth0, float depth1, vec3 translucent, float dither) {
	vec4 finalColor = vec4(0.0);
	vec4 shadowPos = vec4(0.0);
	vec4 worldPos = vec4(0.0);

	//Resolution Control
	if (clamp(texCoord, vec2(0.0), vec2(VOLUMETRICS_RESOLUTION + 1e-3)) == texCoord && ug != 0.0) {
		for (int i = 0; i < VC_SAMPLES; i++) {
			float currentStep = (i + dither) * VC_DISTANCE;
		
			if (depth1 < currentStep || (depth0 < currentStep && translucent == vec3(0.0)) || currentStep >= distanceThreshold || finalColor.a > 0.99){
				break;
			}
			
			worldPos = getWorldSpace(getLogarithmicDepth(currentStep), coord);

			float sampleHeight = abs(VC_HEIGHT - (worldPos.y + cameraPosition.y)) / VC_STRETCHING;

			if (length(worldPos.xz) < distanceThreshold && sampleHeight < 2.0) {
				//Shadow Position
				shadowPos = getShadowSpace(worldPos);

				//Cloud VL
				float shadow0 = shadow2D(shadowtex0, shadowPos.xyz).z;

				if (shadow0 != 0.0) {
					//Circular Fade
					#ifdef VC_FOG
					float fog = length(worldPos.xz) * 0.00005 * (1.0 + rainStrength);
						fog = clamp(exp(-VC_DISTANCE * 2.0 * fog + 0.25), 0.0, 1.0);
					#endif

					worldPos.xyz += cameraPosition;

					float noise = getCloudSample(worldPos.xyz, sampleHeight);
					float lightFactor = clamp(smoothstep(VC_HEIGHT + VC_STRETCHING * noise, VC_HEIGHT - VC_STRETCHING * noise, worldPos.y) * 0.5 + noise * 0.5, 0.0, 1.0);

					//Clouds Color
					vec4 cloudsColor = vec4(mix(lightCol, ambientCol, lightFactor), noise);
					#ifdef VC_FOG
						cloudsColor.a *= fog;
					#endif
						cloudsColor.rgb *= cloudsColor.a;
						cloudsColor.rgb = mix(cloudsColor.rgb, cloudsColor.rgb * translucent, max(float(depth0 < currentStep) - float(isEyeInWater == 1), 0.0));

					finalColor += cloudsColor * (1.0 - finalColor.a);
				}
			}
		}
	}

	return finalColor * ug;
}