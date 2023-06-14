#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

#ifndef SHADERGRAPH_PREVIEW
    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
    #if (SHADERPASS != SHADERPASS_FORWARD)
        #undef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
    #endif
#endif

struct CustomLightingData
{
    float3 positionWS;
    float3 normalWS;
    float3 viewDirectionWS;
    float4 shadowCoord;

    float ambientOcclusion;

    float3 bakedGI;
    float4 shadowMask;
    float fogFactor;
};

#ifndef SHADERGRAPH_PREVIEW
float3 CustomGlobalIllumination(CustomLightingData d)
{
    float3 indirectDiffuse = d.bakedGI * d.ambientOcclusion;
    return indirectDiffuse;
}

float3 CustomLightHandling(CustomLightingData d, Light light)
{
    float3 radiance = light.color * (light.distanceAttenuation * light.shadowAttenuation);
    float diffuse = saturate(dot(d.normalWS, light.direction));
    float3 color = radiance * (diffuse);
    return color;
}
#endif

float3 CalculateCustomLighting(CustomLightingData d)
{
#ifdef SHADERGRAPH_PREVIEW
    float3 lightDir = float3(0.5, 0.5, 0);
    float intensity = saturate(dot(d.normalWS, lightDir));
    return intensity;
#else
    Light mainLight = GetMainLight(d.shadowCoord, d.positionWS, d.shadowMask);
    MixRealtimeAndBakedGI(mainLight, d.normalWS, d.bakedGI);
    float3 color = CustomGlobalIllumination(d);
    color += CustomLightHandling(d, mainLight);

    #ifdef _ADDITIONAL_LIGHTS
        uint numAdditionalLights = GetAdditionalLightsCount();
        for (uint lightI = 0; lightI < numAdditionalLights; lightI++) {
            Light light = GetAdditionalLight(lightI, d.positionWS, d.shadowMask);
            color += CustomLightHandling(d, light);
        }
    #endif

    color = MixFog(color, d.fogFactor);

    return color;
#endif
}

void CalculateCustomLighting_float(float3 Position, float3 Normal, float3 ViewDirection, float AmbientOcclusion, float2 LightmapUV, out float3 Color)
{
    CustomLightingData d;
    d.positionWS = Position;
    d.normalWS = Normal;
    d.viewDirectionWS = ViewDirection;
    d.ambientOcclusion = AmbientOcclusion;

#ifdef SHADERGRAPH_PREVIEW
    d.shadowCoord = 0;
    d.bakedGI = 0;
    d.shadowMask = 0;
    d.fogFactor = 0;
#else
    float4 positionCS = TransformWorldToHClip(Position);
    #if SHADOWS_SCREEN
        d.shadowCoord = ComputeScreenPos(positionCS);
    #else
        d.shadowCoord = TransformWorldToShadowCoord(Position);
    #endif
    float2 lightmapUV;
    OUTPUT_LIGHTMAP_UV(LightmapUV, unity_LightmapST, lightmapUV);
    float3 vertexSH;
    OUTPUT_SH(Normal, vertexSH);
    d.bakedGI = SAMPLE_GI(lightmapUV, vertexSH, Normal);
    d.shadowMask = SAMPLE_SHADOWMASK(lightmapUV);
    d.fogFactor = ComputeFogFactor(positionCS.z);
#endif

    Color = CalculateCustomLighting(d);
}

#endif