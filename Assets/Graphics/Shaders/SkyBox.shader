Shader "AlienProject/SkyBox"
{   
    Properties
    {
        _Color ("Color", Color ) = (1,1,1,1)
        _SkyBox ("SkyBox", Cube) =  "white" {}
    }
    SubShader
    {
        Pass
        {
         Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
            Cull Off ZWrite Off ZClip False

            
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON

            
            TEXTURECUBE(_SkyBox);               SAMPLER(sampler_SkyBox);     

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
            CBUFFER_END

            struct Attributes
            {
                float3 positionOS : POSITION;
                half2 uv : TEXCOORD0;
                half2 lightmapUV : TEXCOORD1;
                half3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half3 uv : TEXCOORD0;
            };

            Varyings Vertex(Attributes i)
            {
                Varyings o;
                float3 worldPos = mul(UNITY_MATRIX_M, float4(i.positionOS, 1.0)).xyz;
                o.uv = i.positionOS;

                o.positionCS = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
                
                return o;
            }


            half4 Fragment(Varyings i) : SV_Target
            {               

                half4 fogCube = SAMPLE_TEXTURECUBE(_SkyBox, sampler_SkyBox, i.uv);
                return fogCube;
                //return i.ff;
            }
            
            ENDHLSL
        }
    }
}