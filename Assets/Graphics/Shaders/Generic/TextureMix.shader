Shader "Plarium/TextureMix"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        _SecondMap("Second Texture", 2D) = "white" {}
        _SecondColor("Second Color", Color) = (1, 1, 1, 1)
        _ThirdMap("Third Texture", 2D) = "white" {}
        _ThirdColor("Third Color", Color) = (1, 1, 1, 1)
        _SplatMap("Splat Map", 2D) = "white" {}
        _Depth("Blend Depth", Range(0.01, 1)) = 0.1


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
            "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" "ShaderModel"="4.5"
        }
        LOD 100

        Blend [_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
        ZWrite [_ZWrite]
        Cull [_Cull]

        Pass
        {
            Name "Unlit"

            AlphaToMask[_AlphaToMask]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // Unity defined keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAMODULATE_ON
            #pragma multi_compile _ SPLATMAP
            #pragma multi_compile _ TWO_TEXTURES
            #pragma multi_compile _ THREE_TEXTURES

            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            float4 _SecondMap_ST;
            half4 _SecondColor;
            float4 _ThirdMap_ST;
            half4 _ThirdColor;
            float4 _SplatMap_ST;
            half _Cutoff;
            half _Surface;
            half _UseAlphaAsColorMask;
            half _Depth;
            CBUFFER_END

            TEXTURE2D(_SecondMap);
            TEXTURE2D(_ThirdMap);
            TEXTURE2D(_SplatMap);
            SAMPLER(sampler_SplatMap);

            #define MAIN_LIGHT_CALCULATE_SHADOWS
            #define _MIXED_LIGHTING_SUBTRACTIVE
            #define  _MAIN_LIGHT_SHADOWS_CASCADE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #if defined(LOD_FADE_CROSSFADE)
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif
            #include "Assets/Graphics/Shaders/PlariumShaderLibrary/PlariumGlobalIllumination.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                float2 splatMapUV : TEXCOORD2;
                half4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                float fogCoord : TEXCOORD2;
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD3;
                float2 splatMapUV : TEXCOORD4;
                half4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            #if TWO_TEXTURES
            inline half3 Blend(half4 texture1, half4 texture2, half2 mask)
            {
                half ma = max(texture1.a + mask.x, texture2.a + mask.y) - _Depth;
                half b1 = max(texture1.a + mask.x - ma, 0);
                half b2 = max(texture2.a + mask.y - ma, 0);

                return (texture1.rgb * b1 + texture2.rgb * b2) / (b1 + b2);
            }
            #endif

            #if THREE_TEXTURES
            inline half3 Blend(half4 texture1, half4 texture2, half4 texture3, half3 mask)
            {
                half a1 = mask.r;
                half a2 = mask.g;
                half a3 = mask.b;

                half ma = max(max(texture1.a + a1, texture2.a + a2), texture3.a + a3) - _Depth;
                half b1 = max(texture1.a + a1 - ma, 0);
                half b2 = max(texture2.a + a2 - ma, 0);
                half b3 = max(texture3.a + a3 - ma, 0);

                return (texture1.rgb * b1 + texture2.rgb * b2 + texture3.rgb * b3) / (b1 + b2 + b3);
            }
            #endif


            Varyings UnlitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                output.positionCS = vertexInput.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.splatMapUV = TRANSFORM_TEX(input.splatMapUV, _SplatMap);
                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
                #if defined(_FOG_FRAGMENT)
                output.fogCoord = vertexInput.positionVS.z;
                #else
                    output.fogCoord = ComputeFogFactor(vertexInput.positionCS.z);
                #endif

                output.positionWS = vertexInput.positionWS;
                output.color = input.color;

                return output;
            }


            void UnlitPassFragment(Varyings input, out half4 outColor : SV_Target0)
            {
                UNITY_SETUP_INSTANCE_ID(input);

                half2 uv = input.uv;
                half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _BaseColor;
                half alpha = texColor.a;

                half4 splatMap = input.color;

                #if SPLATMAP
                    splatMap = SAMPLE_TEXTURE2D(_SplatMap, sampler_SplatMap, input.splatMapUV);
                #endif

                half3 color = texColor * _BaseColor.rgb;
                half4 secondTexColor = texColor;

                #if TWO_TEXTURES
                    secondTexColor = SAMPLE_TEXTURE2D(_SecondMap, sampler_BaseMap, uv) * _SecondColor;
                    color = Blend(texColor, secondTexColor, splatMap.rg) * _BaseColor.rgb;
                #endif

                #if THREE_TEXTURES
                    secondTexColor = SAMPLE_TEXTURE2D(_SecondMap, sampler_BaseMap, uv) * _SecondColor;
                    half4 thirdTexColor = SAMPLE_TEXTURE2D(_ThirdMap, sampler_BaseMap, uv) * _ThirdColor;
                    color = Blend(texColor, secondTexColor, thirdTexColor, splatMap.rgb);
                #endif

                alpha = AlphaDiscard(alpha, _Cutoff);
                color = AlphaModulate(color, alpha);

                #ifdef LOD_FADE_CROSSFADE
                    LODFadeCrossFade(input.positionCS);
                #endif

                #ifdef _DBUFFER
                    ApplyDecalToBaseColor(input.positionCS, color);
                #endif

                half4 shadowParams = GetMainLightShadowParams();
                half3 lightmap = half3(1.0, 1.0, 1.0);
                #if defined LIGHTMAP_ON
                    lightmap = SampleLightmapWithoutNormal(input.staticLightmapUV);
                #endif

                half shadowAttenuation = ComputeShadowAttenuation(input.positionWS, shadowParams);
                color *= CombineLightmapWithRealtimeShadow(lightmap, shadowAttenuation, shadowParams.x);

                color = MixFog(color, ComputeFogFactorUnlit(input.fogCoord));
                alpha = OutputAlpha(alpha, IsSurfaceTypeTransparent(_Surface));

                outColor = half4(color, alpha);
            }
            ENDHLSL
        }
    }
    CustomEditor "Game.Editor.ShaderInspectors.TextureMix"
}