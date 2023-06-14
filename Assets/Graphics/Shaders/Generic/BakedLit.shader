Shader "Plarium/BackedLit"
{
    Properties
    {
        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        [ToggleUI] _UseAlphaAsColorMask("Use Alpha as Color Mask", Float) = 0.0

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
            half _Cutoff;
            half _Surface;
            half _UseAlphaAsColorMask;
            CBUFFER_END

            #define MAIN_LIGHT_CALCULATE_SHADOWS
            //#define _MIXED_LIGHTING_SUBTRACTIVE
            //#define  _MAIN_LIGHT_SHADOWS_CASCADE
            #define SHADOWS_SHADOWMASK

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
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                float fogCoord : TEXCOORD2;
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings UnlitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                output.positionCS = vertexInput.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
                #if defined(_FOG_FRAGMENT)
                output.fogCoord = vertexInput.positionVS.z;
                #else
                    output.fogCoord = ComputeFogFactor(vertexInput.positionCS.z);
                #endif

                output.positionWS = vertexInput.positionWS;

                return output;
            }


            void UnlitPassFragment(Varyings input, out half4 outColor : SV_Target0)
            {
                UNITY_SETUP_INSTANCE_ID(input);

                half2 uv = input.uv;
                half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
                half3 color = texColor.rgb;
                half alpha = texColor.a * _BaseColor.a;

                color *= lerp(_BaseColor.rgb, lerp(1.0, _BaseColor.rgb, texColor.a), _UseAlphaAsColorMask);

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
                    half4 shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
                    lightmap = SampleLightmapWithoutNormal(input.staticLightmapUV) + shadowMask.r;
                    float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                    Light mainLight = GetMainLight(shadowCoord, input.positionWS, shadowMask);
                    half shadowAttenuation = mainLight.shadowAttenuation;
                #else
                    half shadowAttenuation = ComputeShadowAttenuation(input.positionWS, shadowParams);
                #endif



                color *= CombineLightmapWithRealtimeShadow(lightmap, shadowAttenuation, shadowParams.x);
                color = MixFog(color, ComputeFogFactorUnlit(input.fogCoord));
                alpha = OutputAlpha(alpha, IsSurfaceTypeTransparent(_Surface));

                outColor = half4(color, alpha);
            }
            ENDHLSL
        }
    }
    CustomEditor "Game.Editor.ShaderInspectors.BakedLit"
}