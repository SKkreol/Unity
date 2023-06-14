#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#define kDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04)
#define HALF_MIN_SQRT 0.0078125  // 2^-7 == sqrt(HALF_MIN), useful for ensuring HALF_MIN after x^2
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats

// Material Inputs
struct PBRMaterialData
{
    half3 albedo;
    half  metallic;
    half  smoothness;
    half  occlusion;
    half3  additionalLightColor;

    half3 positionWS;
    half3 normalWS;
    half3 bakedGI;
};

struct BRDF
{
    half3 albedo;
    half3 diffuse;
    half3 specular;
    half reflectivity;
    half perceptualRoughness;
    half roughness;
    half roughness2;
    half grazingTerm;

    // We save some light invariant BRDF terms so we don't have to recompute
    // them in the light loop. Take a look at DirectBRDF function for detailed explaination.
    half normalizationTerm;     // roughness * 4.0 + 2.0
    half roughness2MinusOne;    // roughness^2 - 1.0
};


// Return view direction in tangent space, make sure tangentWS.w is already multiplied by GetOddNegativeScale()
half3 GetViewDirectionTangentSpace(half4 tangentWS, half3 normalWS, half3 viewDirWS)
{
    // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
    half3 unnormalizedNormalWS = normalWS;
    const half renormFactor = half(1.0) / length(unnormalizedNormalWS);

    // use bitangent on the fly like in hdrp
    // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
    half crossSign = (tangentWS.w > half(0.0) ? half(1.0) : -half(1.0)); // we do not need to multiple GetOddNegativeScale() here, as it is done in vertex shader
    half3 bitang = crossSign * cross(normalWS.xyz, tangentWS.xyz);

    half3 WorldSpaceNormal = renormFactor * normalWS.xyz;       // we want a unit length Normal Vector node in shader graph

    // to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
    // This is explained in section 2.2 in "surface gradient based bump mapping framework"
    half3 WorldSpaceTangent = renormFactor * tangentWS.xyz;
    half3 WorldSpaceBiTangent = renormFactor * bitang;

    half3x3 tangentSpaceTransform = half3x3(WorldSpaceTangent, WorldSpaceBiTangent, WorldSpaceNormal);
    half3 viewDirTS = mul(tangentSpaceTransform, viewDirWS);

    return viewDirTS;
}


half3 LightingPBR(BRDF brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
{
    float3 lightDirectionWSFloat3 = float3(light.direction);
    float3 halfDir = SafeNormalize(lightDirectionWSFloat3 + float3(viewDirectionWS));

    float NoH = saturate(dot(float3(normalWS), halfDir));
    half LoH = half(saturate(dot(lightDirectionWSFloat3, halfDir)));

    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // BRDFspec = (D * V * F) / 4.0
    // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
    // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155

    // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
    // We further optimize a few light invariant terms
    // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
    float d = NoH * NoH * brdfData.roughness2MinusOne + half(1.00001f);

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(half(0.1h), LoH2) * brdfData.normalizationTerm);

    // On platforms where half actually means something, the denominator has a risk of overflow
    // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
    // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, half(0.0), half(100.0)); // Prevent FP16 overflow on mobiles

    half NdotL = saturate(dot(normalWS, light.direction));
    half3 radiance = light.color * (light.distanceAttenuation * light.shadowAttenuation * NdotL);

    half3 brdf = brdfData.diffuse;
    brdf += brdfData.specular * specularTerm;
    return brdf * radiance;
}

half3 EnvironmentLighting(BRDF brdfData, half3 bakedGI, half3 normalWS, half3 viewDirectionWS, half ao, half4 reflection)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half NoV = saturate(dot(normalWS, viewDirectionWS));
    half3 halfDir = normalize(_MainLightPosition.xyz + viewDirectionWS);
    half VoH = saturate(dot(viewDirectionWS, halfDir));
    
    half oneMinusNoV = half(1.0) - NoV;
    //half oneMinusNoV = 1.0 -NoV;
    half fresnelTerm = (oneMinusNoV * oneMinusNoV) * (oneMinusNoV * oneMinusNoV) * oneMinusNoV;

    half3 indirectSpecular;
    half perceptualRoughness = brdfData.perceptualRoughness * (half(1.7) - half(0.7) *  brdfData.perceptualRoughness);
    half mip = perceptualRoughness * half(6);
    half4 encodedIrradiance = half4(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip));
    half alpha = max(unity_SpecCube0_HDR.w * (encodedIrradiance.a - half(1.0) + half(1.0)), half(0.0));
    //encodedIrradiance.rgb = lerp(encodedIrradiance.rgb, reflection.rgb, reflection.a);
    indirectSpecular = (unity_SpecCube0_HDR.x * PositivePow(alpha, unity_SpecCube0_HDR.y)) * encodedIrradiance.rgb;


    
    half3 color = bakedGI * brdfData.diffuse;
    half surfaceReduction = half(1.0) / (brdfData.roughness2 + half(1.0));
    color += indirectSpecular * half3(surfaceReduction * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm));

    return color;
}


half3 GetVertexLighting(half3 positionWS, half3 normalWS)
{
    half3 vertexLightColor = half3(0.0, 0.0, 0.0);
    uint lightsCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < lightsCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, positionWS);
        half3 lightColor = light.color * light.distanceAttenuation;
        vertexLightColor += LightingLambert(lightColor, light.direction, normalWS);
    }
    return vertexLightColor;
}

Light CustomGetMainLight(half3 bakedGI)
{
    Light light;
    light.direction = half3(_MainLightPosition.xyz);
    //light.distanceAttenuation = saturate(0.2126 * bakedGI.r + 0.7152 * bakedGI.g + 0.0722 * bakedGI.b);
    light.distanceAttenuation = saturate(dot(half3(0.2126, 0.7152, 0.0722), bakedGI));

    light.shadowAttenuation = half(1.0);
    light.color = half3(_MainLightColor.rgb);

    light.layerMask = _MainLightLayerMask;

    return light;
}

BRDF GetBRDFData(PBRMaterialData materialData)
{
    half oneMinusDielectricSpec = kDielectricSpec.a;
    half oneMinusReflectivity = oneMinusDielectricSpec - materialData.metallic * oneMinusDielectricSpec;
    half reflectivity = half(1.0) - oneMinusReflectivity;
    half3 brdfDiffuse = materialData.albedo * oneMinusReflectivity;
    half3 brdfSpecular = lerp(kDieletricSpec.rgb, materialData.albedo, materialData.metallic);

    BRDF brdfData = (BRDF)0;
    brdfData.albedo = materialData.albedo;
    brdfData.diffuse = brdfDiffuse;
    brdfData.specular = brdfSpecular;
    brdfData.reflectivity = reflectivity;
    brdfData.perceptualRoughness = (half(1.0) - materialData.smoothness);
    brdfData.roughness           = max(brdfData.perceptualRoughness * brdfData.perceptualRoughness, half(HALF_MIN_SQRT));
    brdfData.roughness2          = max(brdfData.roughness * brdfData.roughness, half(HALF_MIN));
    brdfData.grazingTerm         = saturate(materialData.smoothness + reflectivity);
    brdfData.normalizationTerm   = brdfData.roughness * half(4.0) + half(2.0);
    brdfData.roughness2MinusOne  = brdfData.roughness2 - half(1.0);
    return brdfData;
}

// Main PBR Fragment Function -> see Lighting.hlsl for reference
half4 GetPBRLighting(PBRMaterialData materialData, Light mainLight, half4 reflection, half3 viewDir)
{
    BRDF brdfData = GetBRDFData(materialData);

    half3 giColor = EnvironmentLighting(brdfData, materialData.bakedGI, materialData.normalWS, viewDir, materialData.occlusion, reflection);
    half3 lightColor = LightingPBR(brdfData, mainLight, materialData.normalWS, viewDir);
    half3 finalColor = saturate(lightColor + giColor) * materialData.occlusion;

    //finalColor += materialData.additionalLightColor * brdfData.diffuse;

    return half4(finalColor, 1.0);
}