Shader "DrawShadows"
{
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline" 
            "UniversalMaterialType" = "Lit" 
            "IgnoreProjector" = "True" 
        }

        Pass
        {
            Name "DrawShadows"
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex Vertex
            #pragma fragment Fragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            struct Varyings
            {       
                float4 positionCS : SV_POSITION;
            };
            
            Varyings Vertex(float3 positionOS : POSITION)
            {             
                Varyings o;
                float3 worldPos = mul(UNITY_MATRIX_M, float4(positionOS, 1.0)).xyz;
                o.positionCS = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
                return o;
            }  
            
            half4 Fragment(Varyings input) : SV_Target
            {                                     
                return unity_DynamicLightmapST;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}