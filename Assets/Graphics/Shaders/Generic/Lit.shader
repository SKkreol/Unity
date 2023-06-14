Shader "Plarium/Lit"
{
    Properties
    {
        [MainColor] _Color("Color", Color) = (1,1,1,1)
        [MainTexture] _MainTex("Albedo", 2D) = "white" {}
        [ToggleUI] _UseAlphaAsColorMask("Use Alpha as Color Mask", Float) = 0.0

        [NoScaleOffset] _MetallicGlossMap("Mask", 2D) = "white" {}
        [ToggleUI] _SwapBandG("Swap B and G chennels in MRAO texture", Float) = 0.0
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 1.0
        _Metallic("Metallic", Range(0.0, 1.0)) = 1.0

        [NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        // BlendMode
        _Surface("__surface", Float) = 0.0
        _Blend("__mode", Float) = 0.0
        _Cull("__cull", Float) = 2.0
        [ToggleUI] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _SrcBlendAlpha("__srcA", Float) = 1.0
        [HideInInspector] _DstBlendAlpha("__dstA", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"
        }
        LOD 300

        //Blend [_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
        ZWrite On
        Cull Off

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex PBRPassVertex
            #pragma fragment PBRPassFragment

            #include "Assets/Graphics/Shaders/PlariumShaderLibrary/PlariumRealtimeLighting.hlsl"
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
            
            half ComputeShadowAttenuation(float3 positionWS, half4 shadowParams)
            {
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
            
                half attenuation;
                half shadowStrength = shadowParams.x;
            
//                 if (shadowParams.y > SOFT_SHADOW_QUALITY_OFF)
//                 {
//                     attenuation = SampleShadowmapFiltered(
//                         TEXTURE2D_SHADOW_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord,
//                         shadowSamplingData);
//                 }
//                 else
//                 {
                    attenuation = real(SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture,
                                                               shadowCoord.xyz));
                //}
            
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

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_MetallicGlossMap);
            SAMPLER(sampler_MetallicGlossMap);
            
            TEXTURE2D(_ReflectionTex);       
            SAMPLER(sampler_ReflectionTex); 
            
            TEXTURE2D(_BlurShadow);       
            SAMPLER(sampler_BlurShadow);
    
            TEXTURECUBE(_FogMap);               SAMPLER(sampler_FogMap);    
            float4x4 _MobileShadowMatrix;
            
            CBUFFER_START(UnityPerMaterial)
                half4 _MainTex_ST;
                half4 _Color;
                half4 _MobileShadowColor;
                half _Smoothness;
                half _Metallic;
                half _SwapBandG;
                half _UseAlphaAsColorMask;
                half _Surface;
                half _Cutoff;
            CBUFFER_END

            struct VertexAttributes
            {
                float3 positionOS : POSITION;
                half3 normalOS : NORMAL;
                half4 tangentOS : TANGENT;
                half2 uv : TEXCOORD0;
                half2 staticLightmapUV : TEXCOORD1;
            };

            struct FragmentVaryings
            {
                float4 positionCS : SV_POSITION;
                half2 uv          : TEXCOORD0;
                
                half4 normalWS    : TEXCOORD1;
                half4 tangentWS   : TEXCOORD2;    // xyz: tangent, w: sign
                half4 biTangentWS : TEXCOORD3;
                
                float2 staticLightmapUV : TEXCOORD4;
                float2 uvShadow : TEXCOORD5;
                //float4 reflectionUV : TEXCOORD8;
                float fogz : TEXCOORD6;
            };
            
            inline half4 ComputeReflectionUV(half4 pos)
            {
                half4 o = pos * 0.5f;
                o.xy = half2(o.x, o.y * _ProjectionParams.x) + o.w;
                o.zw = pos.zw;
                return o;
            }

            FragmentVaryings PBRPassVertex(VertexAttributes input)
            {
                FragmentVaryings output = (FragmentVaryings)0;

                float3 worldPos = mul(UNITY_MATRIX_M, float4(input.positionOS, 1)).xyz;
                output.normalWS.w = worldPos.x;
                output.tangentWS.w = worldPos.y;
                output.biTangentWS.w = worldPos.z;
                
                output.positionCS = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
                
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                
                output.normalWS.xyz = normalize(mul(input.normalOS, (half3x3)UNITY_MATRIX_I_M));
                half sign = input.tangentOS.w * unity_WorldTransformParams.w;
                output.tangentWS.xyz = normalize(mul(input.tangentOS.xyz, (half3x3)UNITY_MATRIX_I_M)); 
                output.biTangentWS.xyz =  sign * cross(output.normalWS.xyz, output.tangentWS.xyz);

                output.staticLightmapUV = input.staticLightmapUV.xy * unity_LightmapST.xy + unity_LightmapST.zw;

                output.fogz = -mul(UNITY_MATRIX_MV, float4(input.positionOS.xyz, 1.0) ).z * _ProjectionParams.w;
                output.uvShadow = mul(_MobileShadowMatrix, float4(worldPos,1)).xy;
                //output.reflectionUV = ComputeReflectionUV(output.positionCS);
                return output;
            }

            half4 PBRPassFragment(FragmentVaryings i): SV_Target0
            {
                PBRMaterialData materialData;

                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                materialData.albedo = albedo.rgb * _Color.rgb;

                half4 mrao = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, i.uv);
                materialData.metallic = mrao.r * _Metallic;
                materialData.smoothness = mrao.b * _Smoothness;
                materialData.occlusion = mrao.g;


                half3 worldPos = half3(i.normalWS.w, i.tangentWS.w, i.biTangentWS.w);
                half4 normalsColors = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv);
                half3 normalTS = UnpackNormal(normalsColors);
                
                half3x3 TBN = half3x3(i.tangentWS.xyz, i.biTangentWS.xyz, i.normalWS.xyz);               
                half3 normals =  mul(normalTS, TBN);
                normals = normalize(normals);
                
                materialData.normalWS = normals;

                materialData.positionWS = worldPos;
                materialData.bakedGI = SampleLightmapWithoutNormal(i.staticLightmapUV);

                Light mainLight = CustomGetMainLight(materialData.bakedGI);

                materialData.additionalLightColor = half3(0.0h, 0.0h, 0.0h);
                
                half4 shadowsSmooth = SAMPLE_TEXTURE2D(_BlurShadow, sampler_BlurShadow, i.uvShadow);
                half shadowIntensity = shadowsSmooth.r * _MobileShadowColor.a;
                half3 shadow = lerp(half(1), _MobileShadowColor.rgb, shadowIntensity);   
                //half2 reflection_uv = i.reflectionUV.xy / i.reflectionUV.w;
                //half4 reflection = SAMPLE_TEXTURE2D(_ReflectionTex, sampler_ReflectionTex, reflection_uv);
                half3 viewDir = GetWorldSpaceNormalizeViewDir(materialData.positionWS);
                
                half4 color = GetPBRLighting(materialData, mainLight, half4(1,1,1,1), viewDir);
                color.rgb *= shadow;
                color.a = 1;
                
                half4 fogCube = SAMPLE_TEXTURECUBE(_FogMap, sampler_FogMap, -viewDir);
                half fc = smoothstep(half(0.03), half(0.18), i.fogz);
            
                //color.rgb = MixFogColor2(fogCube.rgb, color.rgb, fc);
                color.rgb = lerp(color.rgb, fogCube.rgb, fc);

                return color;
            }
            ENDHLSL
        }

//         //This pass it not used during regular rendering, only for lightmap baking.
//         Pass
//         {
//             Name "Meta"
//             Tags
//             {
//                 "LightMode" = "Meta"
//             }
// 
//             Cull [_Cull]
// 
//             HLSLPROGRAM
//             #pragma target 2.0
//             #pragma shader_feature EDITOR_VISUALIZATION
//             #pragma vertex UniversalVertexMeta
//             #pragma fragment UniversalFragmentMetaLit
// 
//             #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//             #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
//             CBUFFER_START(UnityPerMaterial)
//                 float4 _MainTex_ST;
//                 half4 _Color;
//                 half _Smoothness;
//                 half _Metallic;
//                 half _SwapBandG;
//                 half _UseAlphaAsColorMask;
//                 half _Surface;
//                 half _Cutoff;
//             CBUFFER_END
// 
//             TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
//             TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
// 
//             struct Attributes
//             {
//                 float4 positionOS   : POSITION;
//                 float3 normalOS     : NORMAL;
//                 float2 uv0          : TEXCOORD0;
//                 float2 uv1          : TEXCOORD1;
//                 float2 uv2          : TEXCOORD2;
//                 UNITY_VERTEX_INPUT_INSTANCE_ID
//             };
// 
//             struct Varyings
//             {
//                 float4 positionCS   : SV_POSITION;
//                 float2 uv           : TEXCOORD0;
//             #ifdef EDITOR_VISUALIZATION
//                 float2 VizUV        : TEXCOORD1;
//                 float4 LightCoord   : TEXCOORD2;
//             #endif
//             };
// 
//             Varyings UniversalVertexMeta(Attributes input)
//             {
//                 Varyings output = (Varyings)0;
//                 output.positionCS = UnityMetaVertexPosition(input.positionOS.xyz, input.uv1, input.uv2);
//                 output.uv = TRANSFORM_TEX(input.uv0, _MainTex);
//             #ifdef EDITOR_VISUALIZATION
//                 UnityEditorVizData(input.positionOS.xyz, input.uv0, input.uv1, input.uv2, output.VizUV, output.LightCoord);
//             #endif
//                 return output;
//             }
// 
//             half4 UniversalFragmentMeta(Varyings fragIn, MetaInput metaInput)
//             {
//                 #ifdef EDITOR_VISUALIZATION
//                     metaInput.VizUV = fragIn.VizUV;
//                     metaInput.LightCoord = fragIn.LightCoord;
//                 #endif
// 
//                 return UnityMetaFragment(metaInput);
//             }
// 
//             half4 UniversalFragmentMetaLit(Varyings input) : SV_Target
//             {
//                 half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
//                 albedo.rgb = albedo.rgb * _Color.rgb;
//                 half metallic = 0;
//                 half smoothness = 0;
// 
//                 #ifdef METALLICGLOSSMAP
//                     half4 mrao = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, input.uv);
//                     mrao = lerp(mrao, mrao.rbga, _SwapBandG);
//                     metallic = mrao.r * _Metallic;
//                     smoothness = mrao.b * _Smoothness;
//                 #else
//                     metallic = _Metallic;
//                     smoothness = _Smoothness;
//                 #endif
// 
//                 BRDFData brdfData;
//                 half3 a = albedo.rgb;
//                 half alpha = 1;
//                 half3 spec = 1;
//                 InitializeBRDFData(albedo.rgb, metallic, spec, smoothness, alpha, brdfData);
// 
//                 MetaInput metaInput;
//                 metaInput.Albedo = brdfData.diffuse + brdfData.specular * brdfData.roughness * 0.5;
//                 metaInput.Emission = 0;
//                 return UniversalFragmentMeta(input, metaInput);
//             }
//             ENDHLSL
//         }

//         Pass
//         {
//             Name "ShadowCaster"
//             Tags
//             {
//                 "LightMode" = "ShadowCaster"
//             }
// 
//             ZWrite On
//             ZTest LEqual
//             ColorMask 0
//             Cull[_Cull]
// 
//             HLSLPROGRAM
//             #pragma exclude_renderers gles gles3 glcore
//             #pragma target 4.5
// 
//             // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
//             #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
// 
//             #pragma vertex ShadowPassVertex
//             #pragma fragment ShadowPassFragment
// 
//             #pragma shader_feature_local_fragment _ALPHATEST_ON
// 
//             #ifndef UNIVERSAL_SHADOW_CASTER_PASS_INCLUDED
//             #define UNIVERSAL_SHADOW_CASTER_PASS_INCLUDED
// 
// 
//             #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
//             #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
//             #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
// 
//             // Shadow Casting Light geometric parameters. These variables are used when applying the shadow Normal Bias and are set by UnityEngine.Rendering.Universal.ShadowUtils.SetupShadowCasterConstantBuffer in com.unity.render-pipelines.universal/Runtime/ShadowUtils.cs
//             // For Directional lights, _LightDirection is used when applying shadow Normal Bias.
//             // For Spot lights and Point lights, _LightPosition is used to compute the actual light direction because it is different at each shadow caster geometry vertex.
//             TEXTURE2D(_MainTex);
//             SAMPLER(sampler_MainTex);
// 
//             float3 _LightDirection;
//             float3 _LightPosition;
// 
//             CBUFFER_START(UnityPerMaterial)
//             half4 _Color;
//             half _Cutoff;
//             float4 _MainTex_ST;
//             CBUFFER_END
// 
//             struct Attributes
//             {
//                 float4 positionOS : POSITION;
//                 float3 normalOS : NORMAL;
//                 float2 texcoord : TEXCOORD0;
//             };
// 
//             struct Varyings
//             {
//                 float4 positionCS : SV_POSITION;
//                 float2 uv : TEXCOORD0;
//             };
// 
//             float4 GetShadowPositionHClip(Attributes input)
//             {
//                 float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
//                 float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
// 
//                 #if _CASTING_PUNCTUAL_LIGHT_SHADOW
//                     float3 lightDirectionWS = normalize(_LightPosition - positionWS);
//                 #else
//                 float3 lightDirectionWS = _LightDirection;
//                 #endif
// 
//                 float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
// 
//                 #if UNITY_REVERSED_Z
//                 positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
//                 #else
//                     positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
//                 #endif
// 
//                 return positionCS;
//             }
// 
//             Varyings ShadowPassVertex(Attributes input)
//             {
//                 Varyings output;
//                 output.positionCS = GetShadowPositionHClip(input);
//                 output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
//                 return output;
//             }
// 
//             half4 ShadowPassFragment(Varyings input) : SV_TARGET
//             {
//                 Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex)).a, _Color, _Cutoff);
// 
//                 return 0;
//             }
//             #endif
//             ENDHLSL
//         }
    }
    CustomEditor "Game.Editor.ShaderInspectors.Lit"
}