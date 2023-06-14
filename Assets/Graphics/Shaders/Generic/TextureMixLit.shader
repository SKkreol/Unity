Shader "Plarium/TextureMixLit"
{
    Properties
    {
        [MainColor] _Color("Color", Color) = (1,1,1,1)
        [MainTexture] _MainTex("Albedo", 2D) = "white" {}
        [NoScaleOffset] _MetallicGlossMap("Mask", 2D) = "white" {}
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _Metallic("Metallic", Range(0.0, 1.0)) = 0

        [NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}

        _SecondColor("Second Color", Color) = (1, 1, 1, 1)
        _SecondMap("Second Texture", 2D) = "back" {}
        _SecondSmoothness("Second Smoothness", Range(0,1)) = 0.5
        _SecondMetallic("Second Metallic", Range(0,1)) = 0
        _SecondMapNormal("Second Normal Texture", 2D) = "bump" {}

        _ThirdColor("Third Color", Color) = (1, 1, 1, 1)
        _ThirdMap("Third Texture", 2D) = "black" {}
        _ThirdSmoothness("Third Smoothness", Range(0,1)) = 0.5
        _ThirdMetallic("Third Metallic", Range(0,1)) = 0

        _SplatMap("Splat Map", 2D) = "black" {}
        _Depth("Blend Depth", Range(0.01, 1)) = 0.1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"
        }
        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON

            #define MAIN_LIGHT_CALCULATE_SHADOWS
            #define _MIXED_LIGHTING_SUBTRACTIVE
            #define _MAIN_LIGHT_SHADOWS_CASCADE
            #define SHADOWS_SHADOWMASK
            #define LIGHTMAP_SHADOW_MIXING

            #pragma multi_compile_fragment _ BUMPMAP
            #pragma multi_compile_fragment _ TEXTURE_MIX
            #pragma multi_compile_fragment _ SECOND_BUMP
            #pragma multi_compile_fragment _ THREE_TEXTURES
            #pragma multi_compile_fragment _ SPLATMAP

            #pragma vertex vert
            #pragma fragment frag

            #include "Assets/Graphics/Shaders/PlariumShaderLibrary/PlariumRealtimeLighting.hlsl"
            #include "Assets/Graphics/Shaders/PlariumShaderLibrary/PlariumGlobalIllumination.hlsl"
            #include "Assets/Graphics/Shaders/PlariumShaderLibrary/PlariumHelpers.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_MetallicGlossMap);
            SAMPLER(sampler_MetallicGlossMap);

            TEXTURE2D(_SplatMap);
            SAMPLER(sampler_SplatMap);

            TEXTURE2D(_SecondMap);
            TEXTURE2D(_SecondMapNormal);
            TEXTURE2D(_ThirdMap);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;

            half4 _Color;
            half _Smoothness;
            half _Metallic;

            float4 _SplatMap_ST;
            half _Depth;

            float4 _SecondMap_ST;
            half4 _SecondColor;
            half _SecondSmoothness;
            half _SecondMetallic;

            float4 _ThirdMap_ST;
            half4 _ThirdColor;
            half _ThirdSmoothness;
            half _ThirdMetallic;
            CBUFFER_END

            struct VertexAttributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                half2 uv : TEXCOORD0;
                half2 staticLightmapUV : TEXCOORD1;

                half2 splatMapUV : TEXCOORD2;
                half4 color: COLOR0;
            };

            struct FragmentVaryings
            {
                float4 positionCS : SV_POSITION;
                half4 uv : TEXCOORD0;
                half4 color: COLOR0;
                half3 staticLightmapUV_fogFactor : TEXCOORD1;
                half3 positionWS : TEXCOORD2;
                half3 normalWS : TEXCOORD3;
                half4 tangentWS : TEXCOORD4; // xyz: tangent, w: sign
                half4 detailUV: COLOR1;
            };

            FragmentVaryings vert(VertexAttributes input)
            {
                FragmentVaryings output = (FragmentVaryings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = vertexInput.positionCS;
                output.uv.xy = TRANSFORM_TEX(input.uv, _MainTex);
                output.uv.zw = TRANSFORM_TEX(input.splatMapUV, _SplatMap);

                output.detailUV.xy = TRANSFORM_TEX(input.uv, _SecondMap);
                output.detailUV.zw = TRANSFORM_TEX(input.uv, _ThirdMap);

                output.color = input.color;

                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV_fogFactor.xy);

                output.normalWS = normalInput.normalWS;
                output.positionWS = vertexInput.positionWS;

                real sign = input.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                output.tangentWS = tangentWS;

                output.staticLightmapUV_fogFactor.z = ComputeFogFactor(vertexInput.positionCS.z);
                return output;
            }

            half4 frag(FragmentVaryings input): SV_Target0
            {
                PBRMaterialData materialData;

                half2 uv = input.uv.xy;

                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv) * _Color;

                half3 mask = half3(_Metallic, _Smoothness, 1.0);
                mask *= SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv).rgb;

                half4 splatMap = input.color;

                #if SPLATMAP
                    splatMap = SAMPLE_TEXTURE2D(_SplatMap, sampler_SplatMap,  input.uv.zw);
                #endif

                half secondTexHeight = 0.0;
                #if TEXTURE_MIX
                    half4 secondTexColor = SAMPLE_TEXTURE2D(_SecondMap, sampler_MainTex, input.detailUV.xy) * _SecondColor;
                    secondTexHeight = secondTexColor.a;
                    half h = 0.0;
                #if THREE_TEXTURES
                        half4 thirdTexColor = SAMPLE_TEXTURE2D(_ThirdMap, sampler_MainTex, input.detailUV.zw) * _ThirdColor;
					    h = BlendHeight3(half3(albedo.a, secondTexColor.a, thirdTexColor.a), splatMap.xyz, _Depth);
                        albedo.rgb = BlendThreeByHeight(albedo, secondTexColor, thirdTexColor, splatMap.xyz, h);
                        half4 secondMask = half4(_SecondMetallic, _SecondSmoothness, 1.0, secondTexHeight);
                        half4 thirdMask = half4(_ThirdMetallic, _ThirdSmoothness, 1.0, thirdTexColor.a);
                        mask.rgb = saturate(BlendThreeByHeight(half4(mask, albedo.a), secondMask, thirdMask, splatMap.xyz, h));
                #else
                        h = BlendHeight2(half2(albedo.a, secondTexHeight), splatMap.xy, _Depth);
                        albedo.rgb = BlendTwoByHeight(albedo, secondTexColor, splatMap.xy, h);
                        mask.rgb = BlendTwoByHeight(half4(mask, albedo.a), half4(_SecondMetallic, _SecondSmoothness, 1.0, secondTexHeight), splatMap.xy, h);
                #endif
                #endif

                half4 normals = half4(input.normalWS.rgb, 0);
                #if BUMPMAP
                    normals = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv);

                #if SECOND_BUMP
                       half3 secondTexNormal = SAMPLE_TEXTURE2D(_SecondMapNormal, sampler_BumpMap, input.detailUV.xy).rgb;
                       secondTexNormal.rgb = BlendNormalMaps(normals.rgb, secondTexNormal.rgb);
                       normals.rgb = BlendTwo(half4(normals.rgb, albedo.a), half4(secondTexNormal.rgb, secondTexHeight), splatMap.xy, _Depth);
                #endif

                    normals.rgb = TransformTextureNormalsToWorld(normals, input.normalWS.xyz, input.tangentWS);
                #endif

                materialData.albedo = albedo.rgb;
                materialData.metallic = mask.r;
                materialData.smoothness = mask.g;
                materialData.occlusion = mask.b;
                materialData.normalWS = normals.rgb;

                materialData.positionWS = input.positionWS.xyz;
                materialData.additionalLightColor = half3(0, 0, 0);
                materialData.bakedGI = half3(1.0, 1.0, 1.0);

                #if defined LIGHTMAP_ON
                    materialData.bakedGI = SampleLightmapWithoutNormal(input.staticLightmapUV_fogFactor.xy);
                #endif

                half4 shadowParams = GetMainLightShadowParams();
                // Light mainLight = CustomGetMainLight(materialData.bakedGI);
                half4 shadowCoord = TransformWorldToShadowCoord(materialData.positionWS);
                half4 shadowMask = half4(1,1,1,1);
                #if defined LIGHTMAP_ON
                    shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV_fogFactor.xy);
                #endif
                Light mainLight = GetMainLight(shadowCoord, materialData.positionWS, shadowMask);
                // mainLight.shadowAttenuation = ComputeShadowAttenuation(materialData.positionWS, shadowParams);

                // #if defined LIGHTMAP_ON
                //     materialData.bakedGI = CombineLightmapWithRealtimeShadow(materialData.bakedGI, mainLight.shadowAttenuation, shadowParams.x);
                //     materialData.smoothness *= ColorToGrayscale(materialData.bakedGI);
                // #endif

                half4 color = GetPBRLighting(materialData, mainLight);
                color.rgb = MixFog(color.rgb, input.staticLightmapUV_fogFactor.z);
                color.a = 1.0;

                return color;
            }
            ENDHLSL
        }

        //This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            Cull [_Cull]

            HLSLPROGRAM
            #pragma target 2.0
            #pragma shader_feature EDITOR_VISUALIZATION

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON

            #define MAIN_LIGHT_CALCULATE_SHADOWS
            #define _MIXED_LIGHTING_SUBTRACTIVE
            #define _MAIN_LIGHT_SHADOWS_CASCADE
            #define SHADOWS_SHADOWMASK
            #define LIGHTMAP_SHADOW_MIXING

            #pragma multi_compile_fragment _ BUMPMAP
            #pragma multi_compile_fragment _ TEXTURE_MIX
            #pragma multi_compile_fragment _ SECOND_BUMP
            #pragma multi_compile_fragment _ THREE_TEXTURES
            #pragma multi_compile_fragment _ SPLATMAP

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaLit

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
            #include "Assets/Graphics/Shaders/PlariumShaderLibrary/PlariumHelpers.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;

                half4 _Color;
                half _Smoothness;
                half _Metallic;

                float4 _SplatMap_ST;
                half _Depth;

                float4 _SecondMap_ST;
                half4 _SecondColor;
                half _SecondSmoothness;
                half _SecondMetallic;

                float4 _ThirdMap_ST;
                half4 _ThirdColor;
                half _ThirdSmoothness;
                half _ThirdMetallic;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_MetallicGlossMap);
            SAMPLER(sampler_MetallicGlossMap);

            TEXTURE2D(_SplatMap);
            SAMPLER(sampler_SplatMap);

            TEXTURE2D(_SecondMap);
            TEXTURE2D(_SecondMapNormal);
            TEXTURE2D(_ThirdMap);

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 uv0          : TEXCOORD0;
                float2 uv1          : TEXCOORD1;
                half2 splatMapUV : TEXCOORD2;
                half4 color: COLOR0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float4 uv           : TEXCOORD0;
            #ifdef EDITOR_VISUALIZATION
                float2 VizUV        : TEXCOORD1;
                float4 LightCoord   : TEXCOORD2;
            #endif
                half4 color: COLOR0;
                half4 detailUV: COLOR1;
            };

            Varyings UniversalVertexMeta(Attributes input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = UnityMetaVertexPosition(input.positionOS.xyz, input.uv1, half2(0, 0));
                output.uv.xy = TRANSFORM_TEX(input.uv0, _MainTex);
                output.uv.zw = TRANSFORM_TEX(input.splatMapUV, _SplatMap);
                output.detailUV.xy = TRANSFORM_TEX(input.uv0, _SecondMap);
                output.detailUV.zw = TRANSFORM_TEX(input.uv0, _ThirdMap);

                output.color = input.color;
            #ifdef EDITOR_VISUALIZATION
                UnityEditorVizData(input.positionOS.xyz, input.uv0, input.uv1, half2(0, 0), output.VizUV, output.LightCoord);
            #endif
                return output;
            }

            half4 UniversalFragmentMeta(Varyings fragIn, MetaInput metaInput)
            {
                #ifdef EDITOR_VISUALIZATION
                    metaInput.VizUV = fragIn.VizUV;
                    metaInput.LightCoord = fragIn.LightCoord;
                #endif

                return UnityMetaFragment(metaInput);
            }

            half4 UniversalFragmentMetaLit(Varyings input) : SV_Target
            {
                half2 uv = input.uv.xy;

                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv) * _Color;

                half3 mask = half3(_Metallic, _Smoothness, 1.0);
                mask *= SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv).rgb;

                half4 splatMap = input.color;

                #if SPLATMAP
                    splatMap = SAMPLE_TEXTURE2D(_SplatMap, sampler_SplatMap,  input.uv.zw);
                #endif

                half secondTexHeight = 0.0;
                #if TEXTURE_MIX
                    half4 secondTexColor = SAMPLE_TEXTURE2D(_SecondMap, sampler_MainTex, input.detailUV.xy) * _SecondColor;
                    secondTexHeight = secondTexColor.a;
                    half h = 0.0;
                #if THREE_TEXTURES
                        half4 thirdTexColor = SAMPLE_TEXTURE2D(_ThirdMap, sampler_MainTex, input.detailUV.zw) * _ThirdColor;
					    h = BlendHeight3(half3(albedo.a, secondTexColor.a, thirdTexColor.a), splatMap.xyz, _Depth);
                        albedo.rgb = BlendThreeByHeight(albedo, secondTexColor, thirdTexColor, splatMap.xyz, h);
                        half4 secondMask = half4(_SecondMetallic, _SecondSmoothness, 1.0, secondTexHeight);
                        half4 thirdMask = half4(_ThirdMetallic, _ThirdSmoothness, 1.0, thirdTexColor.a);
                        mask.rgb = saturate(BlendThreeByHeight(half4(mask, albedo.a), secondMask, thirdMask, splatMap.xyz, h));
                #else
                        h = BlendHeight2(half2(albedo.a, secondTexHeight), splatMap.xy, _Depth);
                        albedo.rgb = BlendTwoByHeight(albedo, secondTexColor, splatMap.xy, h);
                        mask.rgb = BlendTwoByHeight(half4(mask, albedo.a), half4(_SecondMetallic, _SecondSmoothness, 1.0, secondTexHeight), splatMap.xy, h);
                #endif
                #endif


                BRDFData brdfData;
                half3 a = albedo.rgb;
                half alpha = 1;
                half3 spec = 1;
                InitializeBRDFData(albedo.rgb, mask.r, spec, mask.g, alpha, brdfData);

                MetaInput metaInput;
                metaInput.Albedo = brdfData.diffuse + brdfData.specular * brdfData.roughness * 0.5;
                metaInput.Emission = 0;
                return UniversalFragmentMeta(input, metaInput);
            }
            ENDHLSL
        }
    }
    CustomEditor "Game.Editor.ShaderInspectors.LitTextureMix"
}