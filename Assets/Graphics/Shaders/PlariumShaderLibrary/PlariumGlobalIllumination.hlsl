#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
half3 SampleLightmapWithoutNormal(float2 uv)
{
    #ifdef UNITY_LIGHTMAP_FULL_HDR
                    bool encodedLightmap = false;
    #else
    bool encodedLightmap = true;
    #endif

    half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);
    half4 transformCoords = half4(1, 1, 0, 0);
    half3 lm = SampleSingleLightmap(
        TEXTURE2D_LIGHTMAP_ARGS(unity_Lightmap, samplerunity_Lightmap), uv,
        transformCoords, encodedLightmap, decodeInstructions);

    return lm;
}

half ComputeFogFactorUnlit(float fogCoord)
{
    half fogFactor = 0;
    #if defined(_FOG_FRAGMENT)
    #if (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))
                        float viewZ = -fogCoord;
                        float nearToFarZ = max(viewZ - _ProjectionParams.y, 0);
                        fogFactor= ComputeFogFactorZ0ToFar(nearToFarZ);
    #endif
    #else
    fogFactor = fogCoord;
    #endif

    return fogFactor;
}

half ComputeShadowAttenuation(float3 positionWS, half4 shadowParams)
{
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();

    half attenuation;
    half shadowStrength = shadowParams.x;

    if (shadowParams.y > SOFT_SHADOW_QUALITY_OFF)
    {
        attenuation = SampleShadowmapFiltered(
            TEXTURE2D_SHADOW_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord,
            shadowSamplingData);
    }
    else
    {
        attenuation = real(SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture,
                                                   shadowCoord.xyz));
    }

    attenuation = LerpWhiteTo(attenuation, shadowStrength);
    half shadowAttenuation = BEYOND_SHADOW_FAR(shadowCoord) ? 1.0 : attenuation;

    return shadowAttenuation;
}

half3 CombineLightmapWithRealtimeShadow(half3 lightmap, half3 shadowmap, half shadowStrength)
{
    half3 estimatedLightContributionMaskedByInverseOfShadow = (1.0 - shadowmap) * _MainLightColor.rgb;
    half3 subtractedLightmap = lightmap - estimatedLightContributionMaskedByInverseOfShadow;
    half3 realtimeShadow = max(subtractedLightmap, _SubtractiveShadowColor.xyz);
    realtimeShadow = lerp(lightmap, realtimeShadow, shadowStrength);
    half3 shadows = min(lightmap, realtimeShadow);

    return shadows;
}
