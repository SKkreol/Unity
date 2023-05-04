Shader "AlienProject/SampleWorldUV"
{   
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        _OffSet ("OffSet", Vector) = (1,1,0,0)
    }
    SubShader
    {
        Tags 
        {
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline" 
            "UniversalMaterialType" = "Lit" 
            "IgnoreProjector" = "True" 
            "ShaderModel"="4.5"
        }
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            
            CBUFFER_START(UnityPerMaterial)
                half4 _OffSet;
            CBUFFER_END
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap); 

            struct Attributes
            {
                float3 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half3 worldPos : TEXCOORD0;

            };

            Varyings Vertex(Attributes i)
            {
                Varyings o;
                float3 worldPos = mul(UNITY_MATRIX_M, float4(i.positionOS, 1.0)).xyz;

                o.positionCS = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
                o.worldPos = worldPos;
                return o;
            }

            half4 Fragment(Varyings i) : SV_Target
            {
                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.worldPos.xz/_OffSet.xy - _OffSet.zw);
                half2 tt = (i.worldPos.xz- float2(4.3222, 13.4793))/_OffSet.xy - _OffSet.zw;
                return float4(tt, 0, 1);
            }
            
            ENDHLSL
        }
    }
}