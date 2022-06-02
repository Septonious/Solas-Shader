vec4 distortShadow(vec4 shadowpos, float distortFactor) {
	shadowpos.xy *= 1.0 / distortFactor;
	shadowpos.z = shadowpos.z * 0.2;
	shadowpos = shadowpos * 0.5 + 0.5;

	return shadowpos;
}

vec4 getShadowSpace(vec4 wpos) {
	wpos = shadowModelView * wpos;
	wpos = shadowProjection * wpos;
	wpos /= wpos.w;
	
	float distb = sqrt(wpos.x * wpos.x + wpos.y * wpos.y);
	float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
	wpos = distortShadow(wpos, distortFactor);
	
	return wpos;
}

vec3 getVolumetricLight(vec3 viewPos, vec2 coord, float z0, float z1, vec3 translucent, float dither) {
	vec3 vl = vec3(0.0);
	vec4 worldPos = vec4(0.0);
	vec4 shadowPos = vec4(0.0);

	//Depths
	float depth0 = getLinearDepth2(z0);
	float depth1 = getLinearDepth2(z1);
		
	//Resolution Control
	if (clamp(texCoord, vec2(0.0), vec2(VOLUMETRICS_RESOLUTION + 1e-3)) == texCoord) {
		for(int i = 0; i < VL_SAMPLES; i++) {
			float minDist = (i + dither) * 16.0;

			if (depth1 < minDist || (depth0 < minDist && translucent == vec3(0.0))) {
				break;
			}

			worldPos = getWorldSpace(getLogarithmicDepth(minDist), coord);
			shadowPos = getShadowSpace(worldPos);

			//Circular Fade
			if (length(shadowPos.xy * 2.0 - 1.0) < 1.0 && length(worldPos.xz) < 256.0) {
				float shadow0 = shadow2D(shadowtex0, shadowPos.xyz).z;
					
				vec3 shadowCol = vec3(0.0);
				#ifdef SHADOW_COLOR
				if (shadow0 < 1.0) {
					float shadow1 = shadow2D(shadowtex1, shadowPos.xyz).z;
					if (shadow1 > 0.0) {
						shadowCol = texture2D(shadowcolor0, shadowPos.xy).rgb;
						shadowCol *= shadowCol * shadow1;
					}
				}
				#endif

				vec3 shadow = clamp(shadowCol * (1.0 - shadow0) + shadow0, vec3(0.0), vec3(1.0));
				shadow = mix(shadow, shadow * translucent * translucent, max(float(depth0 < minDist) - float(isEyeInWater == 1), 0.0));

				//Fog Altitude
				vec3 fogPosition = worldPos.xyz + cameraPosition.xyz;
				float worldHeightFactor = clamp(fogPosition.y * 0.001 * FOG_HEIGHT, 0.0, 1.0);
				shadow *= 1.0 - worldHeightFactor;

				vl += shadow;
			}
		}
	}
	
	return vl * lightCol;
}