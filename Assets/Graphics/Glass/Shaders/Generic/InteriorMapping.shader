Shader "Plarium/Environment/InteriorMapping"
{
    Properties
    {
        [NoScaleOffset] _InteriorMap ("Interior map", CUBE) = "" {}
        _RoomDepth("Depth", Range(0.1, 2.0)) = 1
        _BaseMap("Dirt texture", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        _InteriorColor("Interior Color", Color) = (1, 1, 1, 1)
        _MaskSize ("Mask size", Range(0.0, 5.0)) = 0.5
        _CubeMapMultiplier("CubeMap Multiplier", Range(0.0 , 2.0)) = 1.0
        [NoScaleOffSet] _CubeMap ("Cube Map", Cube) = "white"
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" "ShaderModel"="4.5"
        }
        Pass
        {
            Cull Back
            ZTest LEqual
            ZWrite On

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5
            #pragma vertex vert
            #pragma fragment frag

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                half3 positionOS : POSITION;

                half2 uv : TEXCOORD0;
                float2 lightmapUV : TEXCOORD1;

                half3 normalOS : NORMAL;
                half4 tangentOS : TANGENT;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;

                half2 uv : TEXCOORD0;
                float2 lightmapUV : TEXCOORD1;
                half2 uvGlass : TEXCOORD2;

                half3 normalWS : TEXCOORD3;
                half4 viewDirectionTGfog : TEXCOORD4; // w - fog factor.
                half3 viewDirectionWS : TEXCOORD5;
                half2 maskUV : TEXCOORD6;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor, _BaseMap_ST, _InteriorColor;
                half _MaskSize;
                half _RoomDepth;
                half _CubeMapMultiplier;
            CBUFFER_END

            TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
            TEXTURECUBE(_CubeMap);          SAMPLER(sampler_CubeMap);
            TEXTURECUBE(_InteriorMap);      SAMPLER(sampler_InteriorMap);

            #ifdef DOTS_INSTANCING_ON
            #ifdef UNITY_DOTS_INSTANCING_ENABLED
                UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
                    UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
                    UNITY_DOTS_INSTANCED_PROP(float4, _InteriorColor)
                    UNITY_DOTS_INSTANCED_PROP(float , _MaskSize)
                    UNITY_DOTS_INSTANCED_PROP(float , _RoomDepth)
                    UNITY_DOTS_INSTANCED_PROP(float , _CubeMapMultiplier)
                UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

                #define _BaseColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__BaseColor)
                #define _InteriorColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__InteriorColor)
                #define _MaskSize            UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__MaskSize)
                #define _RoomDepth            UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__RoomDepth)
                #define _CubeMapMultiplier            UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__CubeMapMultiplier)
            #endif
            #endif

            Varyings vert(Attributes i)
            {
                Varyings o = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);

                o.normalWS.xyz = TransformObjectToWorldNormal(i.normalOS);
                half3 tangentWS = TransformObjectToWorldDir(i.tangentOS.xyz);
                half crossSign = i.tangentOS.w * unity_WorldTransformParams.w;
                half3 biTangentWS = crossSign * cross(o.normalWS.xyz, tangentWS.xyz);

                half3x3 TBN = half3x3(tangentWS, biTangentWS, o.normalWS.xyz);
                float3 positionWS = TransformObjectToWorld(i.positionOS);
                o.viewDirectionWS = positionWS - _WorldSpaceCameraPos;
                half3 TangentSpaceViewDirection = mul(TBN,  GetWorldSpaceViewDir(positionWS));
                o.viewDirectionTGfog.xyz = TangentSpaceViewDirection;

                o.positionCS = TransformWorldToHClip(positionWS);
                o.viewDirectionTGfog.w = ComputeFogFactor(o.positionCS.z);
                o.uv = -i.uv;
                o.maskUV = (i.uv-0.5h)*_MaskSize;
                o.uvGlass = TRANSFORM_TEX(i.uv, _BaseMap);
                return o;
            }

            half4 Glass(half2 uv, half3 normalWS, half2 maskUV, half3 viewDir)
            {
                half texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv).r;
                half3 V = normalize(viewDir);
                half roughness = texColor;

                half mask = distance(half2(0.0h, 0.0h), maskUV);
                mask = saturate(mask * roughness);
                half invertedMask = (1.0h - mask * _BaseColor.a) * _CubeMapMultiplier;

                half3 indirectSpecular = SAMPLE_TEXTURECUBE(_CubeMap, sampler_CubeMap, V).rgb * invertedMask;
                half4 color = _BaseColor * mask;
                half3 finalColor = (indirectSpecular + color.rgb) * 0.5h;
                half alpha = saturate(color.a + indirectSpecular);

                return half4(finalColor, alpha);
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half4 glassColor = Glass(i.uvGlass, i.normalWS.xyz, i.maskUV, i.viewDirectionWS);

                half2 uv = i.uv.xy;
                uv = frac(uv);
                uv = uv * 2 - 1;
                half3 cubeUV = half3(uv.x, uv.y, -_RoomDepth);
                half3 id = 1/i.viewDirectionTGfog.xyz;
                half3 absID = abs(id);

                half3 k = absID - cubeUV * id;
                half kMin = min(min(k.x, k.y), k.z);
                half3 kMinTangent = kMin.xxx * i.viewDirectionTGfog.xyz;

                half3 pos = cubeUV + kMinTangent;
                pos.xy = -pos.xy;
                half3 color = SAMPLE_TEXTURECUBE(_InteriorMap, sampler_InteriorMap, pos).rgb * _InteriorColor.rgb;

                half3 final = lerp(color, glassColor.rgb, glassColor.a); // Blend SrcAlphaOneMinusSrcAlpha.

                final = MixFog(final, i.viewDirectionTGfog.w);
                return half4(final, 1);
            }
            ENDHLSL
        }
    }
}