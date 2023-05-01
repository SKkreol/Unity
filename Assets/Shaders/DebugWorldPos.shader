Shader "AlienProject/DebugWorldPos"
{   
    Properties
    {
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
            CBUFFER_END

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
                return half4(i.worldPos, 1);
            }
            
            ENDHLSL
        }
    }
}