Shader "Hidden/FullScreenTriangle"
{   
    SubShader
    {
        Pass
        {
            ZTest Always
            ZWrite Off
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_Tex);
            SAMPLER(sampler_Tex);

            struct Attributes
            {
                float2 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half2 uv : TEXCOORD0;
            };

            Varyings Vertex(Attributes i)
            {
                Varyings o;
                o.positionCS = float4(i.positionOS, 0, 1);
                o.uv = i.positionOS * half2(0.5, -0.5) + 0.5;
                return o;
            }

            half4 Fragment(Varyings i) : SV_Target
            {
                return SAMPLE_TEXTURE2D(_Tex, sampler_Tex, i.uv);;
            }
            ENDHLSL
        }
    }
}