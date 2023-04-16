Shader "Shadow"
{   
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        _Color ("Color", Color ) = (1,1,1,1)
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"}
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_BlurShadow);
            SAMPLER(sampler_BlurShadow);      
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);       

            float4x4 _MobileShadowMatrix;
            
            CBUFFER_START(UnityPerMaterial)

                float4 _MobileShadowColor;
                float4 _BaseMap_ST;
                float4 _Color;
            CBUFFER_END

            struct Attributes
            {
                float3 positionOS : POSITION;
                half2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half2 uv : TEXCOORD0;
                float2 shadowCoord : TEXCOORD1;
            };

            Varyings Vertex(Attributes i)
            {
                Varyings o;
                float3 worldPos = mul(UNITY_MATRIX_M, float4(i.positionOS, 1.0)).xyz;
                o.positionCS = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
		        o.shadowCoord = mul(_MobileShadowMatrix, float4(worldPos,1)).xy;
                o.uv = i.uv*_BaseMap_ST.xy + _BaseMap_ST.zw;
                return o;
            }

            half4 Fragment(Varyings i) : SV_Target
            {
                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
            
                half4 shadowsSmooth = SAMPLE_TEXTURE2D(_BlurShadow, sampler_BlurShadow, i.shadowCoord);
                half3 shadow = lerp(1, _MobileShadowColor.rgb, shadowsSmooth.r*_MobileShadowColor.a);
                
                return half4(shadow, 1) * albedo * _Color;
            }
            
            ENDHLSL
        }
    }
}